# frozen_string_literal: true

RSpec.describe UserNotifications do
  fab!(:student) { Fabricate(:user, email: "taro@st.kyoto-u.ac.jp", active: false) }
  fab!(:outsider) { Fabricate(:user, email: "hanako@example.com", active: false) }

  # 纯文本里不能有任何网址；HTML 里不能有链接和图片
  let(:url_pattern) { %r{https?://|www\.|[a-z0-9-]+\.(com|jp|net|org|io)\b}i }

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
    SiteSetting.kuu_kyoto_email_activation_code_enabled = true
  end

  def send_signup_email(user)
    email_token = user.email_tokens.create!(email: user.email, scope: EmailToken.scopes[:signup])
    Jobs::CriticalUserEmail.new.execute(
      type: "signup",
      user_id: user.id,
      email_token: email_token.token,
    )
    ActionMailer::Base.deliveries.last
  end

  def without_doctype(html)
    html.sub(/\A<!DOCTYPE[^>]*>/i, "").gsub(/xmlns(:\w+)?="[^"]*"/, "")
  end

  it "sends Kyoto students a code and not a single link" do
    mail = send_signup_email(student)

    text = mail.text_part.body.to_s
    html = without_doctype(mail.html_part.body.to_s)
    code = text[/\d{6}/]

    expect(mail.to).to eq([student.email])
    expect(code).to be_present
    expect(DiscourseKuuKyotoEmail::ActivationCode.verify(student, code)).to eq(:ok)
    expect(text).not_to match(url_pattern)
    expect(html).to include(code)
    expect(html).not_to match(/<a[\s>]|href=|<img[\s>]/i)
    expect(html).not_to match(url_pattern)
    expect(mail.header[DiscourseKuuKyotoEmail::ActivationCodeMail::MARKER_HEADER]).to be_nil
  end

  it "sends the same code again when the student asks for another email" do
    first_code = send_signup_email(student).text_part.body.to_s[/\d{6}/]
    second_code = send_signup_email(student).text_part.body.to_s[/\d{6}/]

    expect(second_code).to eq(first_code)
  end

  it "uses the same code mail for the activation reminder" do
    email_token =
      student.email_tokens.create!(email: student.email, scope: EmailToken.scopes[:signup])
    Jobs::UserEmail.new.execute(
      type: "activation_reminder",
      user_id: student.id,
      email_token: email_token.token,
    )

    expect(ActionMailer::Base.deliveries.last.text_part.body.to_s).not_to match(url_pattern)
  end

  it "keeps the activation link for other email domains" do
    mail = send_signup_email(outsider)

    expect(mail.text_part.body.to_s).to include("/u/activate-account/")
  end

  it "keeps the activation link when the setting is off" do
    SiteSetting.kuu_kyoto_email_activation_code_enabled = false

    mail = send_signup_email(student)

    expect(mail.text_part.body.to_s).to include("/u/activate-account/")
    expect(DiscourseKuuKyotoEmail::ActivationCode.where(user_id: student.id)).to be_empty
  end
end
