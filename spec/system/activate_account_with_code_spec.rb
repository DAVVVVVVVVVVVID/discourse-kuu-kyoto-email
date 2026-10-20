# frozen_string_literal: true

RSpec.describe "Activate account with code" do
  let(:signup_page) { PageObjects::Pages::Signup.new }
  let(:login_page) { PageObjects::Pages::Login.new }
  let(:activation_code) { PageObjects::Components::KuuKyotoEmailActivationCode.new }

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
    SiteSetting.kuu_kyoto_email_activation_code_enabled = true
    SiteSetting.enable_local_logins_via_code = false
    Jobs.run_immediately!
  end

  def code_sent_to(email)
    mail = ActionMailer::Base.deliveries.reverse.find { |delivery| delivery.to == [email] }
    mail.text_part.body.to_s[/\d{6}/]
  end

  it "lets a new student activate with the code from the email and enter the forum" do
    signup_page.open.fill_email("taro@st.kyoto-u.ac.jp").fill_username("taro")
    signup_page.fill_password("a-long-enough-password")
    expect(signup_page).to have_valid_fields
    signup_page.click_create_account

    expect(page).to have_current_path("/u/account-created")
    expect(activation_code).to have_sent_to("taro@st.kyoto-u.ac.jp")
    expect(activation_code).to have_resend_countdown
    expect(page).to have_no_css(".account-created .activation-controls .resend")

    activation_code.activate_with(code_sent_to("taro@st.kyoto-u.ac.jp"))

    expect(page).to have_css(".header-dropdown-toggle.current-user")
  end

  context "when the student closed the waiting page" do
    fab!(:student) do
      Fabricate(
        :user,
        username: "hanako",
        email: "hanako@st.kyoto-u.ac.jp",
        password: "a-long-enough-password",
        active: false,
      )
    end

    def send_activation_email
      email_token =
        student.email_tokens.create!(email: student.email, scope: EmailToken.scopes[:signup])
      EmailToken.enqueue_signup_email(email_token)
    end

    it "lets the student enter the code after trying to log in" do
      send_activation_email
      login_page.open.fill(username: "hanako", password: "a-long-enough-password").click_login

      activation_code.activate_with("not-a-code")
      expect(page).to have_css(".kuu-kyoto-email-not-activated-modal .form-kit__errors")

      code = code_sent_to("hanako@st.kyoto-u.ac.jp")
      wrong_code = code == "000000" ? "111111" : "000000"
      activation_code.activate_with(wrong_code)
      expect(activation_code).to have_error(I18n.t("kuu_kyoto_email.activation_code.invalid"))

      activation_code.activate_with(code)

      expect(page).to have_css(".header-dropdown-toggle.current-user")
    end

    it "tells the student to resend when the code has expired" do
      freeze_time(1.hour.ago) { send_activation_email }

      login_page.open.fill(username: "hanako", password: "a-long-enough-password").click_login

      expect(page).to have_css(
        ".kuu-kyoto-email-not-activated-modal__no-code",
        text: I18n.t("js.kuu_kyoto_email.activation_code.no_valid_code"),
      )

      expect(activation_code).to have_resend_available
      activation_code.resend

      expect(page).to have_no_css(".kuu-kyoto-email-not-activated-modal__no-code")
      expect(activation_code).to have_resent_message
      expect(activation_code).to have_resend_countdown
      activation_code.activate_with(code_sent_to("hanako@st.kyoto-u.ac.jp"))
      expect(page).to have_css(".header-dropdown-toggle.current-user")
    end
  end
end
