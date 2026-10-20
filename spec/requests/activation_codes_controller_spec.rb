# frozen_string_literal: true

RSpec.describe DiscourseKuuKyotoEmail::ActivationCodesController do
  fab!(:student) { Fabricate(:user, email: "taro@st.kyoto-u.ac.jp", active: false) }

  let(:code) { DiscourseKuuKyotoEmail::ActivationCode.issue!(student) }
  let(:wrong_code) { code == "000000" ? "111111" : "000000" }

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
    SiteSetting.kuu_kyoto_email_activation_code_enabled = true
  end

  def activate(login: student.username, with: code)
    post "/kuu-kyoto-email/activation-code.json", params: { login:, code: with }
  end

  describe "#create" do
    it "activates the account and logs the user in" do
      activate(login: student.email)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("needs_approval" => false, "redirect_to" => "/")
      expect(student.reload).to be_active
      expect(student.email_confirmed?).to eq(true)
      expect(session[:current_user_id]).to eq(student.id)
    end

    it "leaves the account waiting when it still needs approval" do
      SiteSetting.must_approve_users = true
      student.update!(approved: false)

      activate

      expect(response.parsed_body["needs_approval"]).to eq(true)
      expect(student.reload).to be_active
      expect(session[:current_user_id]).to be_nil
    end

    it "rejects a wrong code and locks it after 5 tries" do
      4.times { activate(with: wrong_code) }
      expect(response.parsed_body["errors"]).to contain_exactly(
        I18n.t("kuu_kyoto_email.activation_code.invalid"),
      )

      activate(with: wrong_code)
      activate

      expect(response.parsed_body["errors"]).to contain_exactly(
        I18n.t("kuu_kyoto_email.activation_code.locked"),
      )
      expect(student.reload).not_to be_active
    end

    it "rejects an expired code" do
      issued_code = code

      freeze_time(31.minutes.from_now) { activate(with: issued_code) }

      expect(response.parsed_body["errors"]).to contain_exactly(
        I18n.t("kuu_kyoto_email.activation_code.expired"),
      )
    end

    it "rejects the old code after a new one is sent" do
      old_code = code
      new_code = DiscourseKuuKyotoEmail::ActivationCode.issue!(student)

      activate(with: old_code) if old_code != new_code

      expect(student.reload).not_to be_active if old_code != new_code
      activate(with: new_code)
      expect(student.reload).to be_active
    end

    it "answers an unknown account the same as a wrong code" do
      activate(login: "nobody")

      expect(response.parsed_body["errors"]).to contain_exactly(
        I18n.t("kuu_kyoto_email.activation_code.invalid"),
      )
    end

    it "limits attempts per IP" do
      RateLimiter.enable

      10.times { activate(login: "nobody", with: wrong_code) }
      activate

      expect(response.status).to eq(429)
      expect(student.reload).not_to be_active
    end

    it "is not available when the setting is off" do
      SiteSetting.kuu_kyoto_email_activation_code_enabled = false

      activate

      expect(response.status).to eq(404)
    end
  end
end
