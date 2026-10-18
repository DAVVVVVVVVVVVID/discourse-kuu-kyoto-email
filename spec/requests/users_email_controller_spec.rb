# frozen_string_literal: true

RSpec.describe UsersEmailController do
  fab!(:user, :kuu_kyoto_user)
  fab!(:admin)
  fab!(:other_user) { Fabricate(:user, email: "taken@example.com") }

  let!(:kyoto_email) { DiscourseKuuKyotoEmail::KyotoEmail.for(user) }

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
  end

  def last_email_token
    Jobs::CriticalUserEmail.jobs.last["args"].first["email_token"]
  end

  describe "#create" do
    before { sign_in(user) }

    it "lets a Kyoto user add a personal email and makes it primary once confirmed" do
      post "/u/#{user.username}/preferences/email.json", params: { email: "Taro@Example.com" }
      expect(response.status).to eq(200)

      put "/u/confirm-new-email/#{last_email_token}.json"
      expect(response.status).to eq(200)

      user.reload
      expect(user.email).to eq("taro@example.com")
      expect(user.secondary_emails).to contain_exactly(kyoto_email)
    end

    it "invalidates links already sent to the Kyoto email once the personal email takes over" do
      reset_token =
        user.email_tokens.create!(email: kyoto_email, scope: EmailToken.scopes[:password_reset])
      post "/u/#{user.username}/preferences/email.json", params: { email: "taro@example.com" }
      put "/u/confirm-new-email/#{last_email_token}.json"

      expect(EmailToken.confirmable(reset_token.token)).to be_nil
    end

    it "rejects a domain in blocked_email_domains" do
      SiteSetting.blocked_email_domains = "spam.example"

      post "/u/#{user.username}/preferences/email.json", params: { email: "taro@spam.example" }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"].first).to include(I18n.t("user.email.not_allowed"))
    end

    it "rejects a screened email" do
      ScreenedEmail.create!(email: "taro@example.com", action_type: ScreenedEmail.actions[:block])

      post "/u/#{user.username}/preferences/email.json", params: { email: "taro@example.com" }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"].first).to include(I18n.t("user.email.blocked"))
    end

    it "rejects an email that another account already uses" do
      SiteSetting.hide_email_address_taken = false

      post "/u/#{user.username}/preferences/email.json", params: { email: other_user.email }

      expect(response.status).to eq(422)
    end

    it "rejects another Kyoto email" do
      post "/u/#{user.username}/preferences/email.json",
           params: {
             email: "another@st.kyoto-u.ac.jp",
           }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to contain_exactly(
        I18n.t("kuu_kyoto_email.errors.kyoto_domain_not_allowed"),
      )
    end

    it "rejects a Kyoto email for an account without one" do
      sign_in(admin)

      post "/u/#{admin.username}/preferences/email.json",
           params: {
             email: "admin@st.kyoto-u.ac.jp",
           }

      expect(response.status).to eq(422)
    end

    it "keeps the domain restriction when the plugin is disabled" do
      SiteSetting.kuu_kyoto_email_enabled = false

      post "/u/#{user.username}/preferences/email.json", params: { email: "taro@example.com" }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"].first).to include(I18n.t("user.email.not_allowed"))
    end
  end

  describe "#update" do
    it "rejects replacing the Kyoto email while it is the primary email" do
      sign_in(user)

      put "/u/#{user.username}/preferences/email.json", params: { email: "taro@example.com" }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to contain_exactly(
        I18n.t("kuu_kyoto_email.errors.kyoto_email_locked"),
      )
    end

    it "lets a user replace their personal email with another personal email" do
      user.user_emails.create!(email: "old@example.com", skip_validate_email: true)
      DiscourseKuuKyotoEmail::KyotoEmail.promote_personal_email!(user, "old@example.com")
      sign_in(user)

      put "/u/#{user.username}/preferences/email.json", params: { email: "new@example.com" }
      put "/u/confirm-new-email/#{last_email_token}.json"

      user.reload
      expect(user.emails).to eq(["new@example.com", kyoto_email])
    end

    it "lets an admin correct someone's Kyoto email" do
      sign_in(admin)

      put "/u/#{user.username}/preferences/email.json", params: { email: "fixed@st.kyoto-u.ac.jp" }
      expect(response.status).to eq(200)
      sign_in(user)

      put "/u/confirm-new-email/#{last_email_token}.json"

      user.reload
      expect(user.emails).to eq(["fixed@st.kyoto-u.ac.jp"])
      expect(DiscourseKuuKyotoEmail::KyotoEmail.for(user)).to eq("fixed@st.kyoto-u.ac.jp")
    end
  end

  describe "#confirm_new_email" do
    it "keeps the Kyoto email when a change requested before the plugin was enabled is confirmed" do
      SiteSetting.kuu_kyoto_email_enabled = false
      SiteSetting.allowed_email_domains = ""
      EmailUpdater.new(guardian: user.guardian, user:).change_to("taro@example.com")
      token = last_email_token
      SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
      SiteSetting.kuu_kyoto_email_enabled = true

      put "/u/confirm-new-email/#{token}.json"

      user.reload
      expect(user.emails).to eq(["taro@example.com", kyoto_email])
    end
  end
end
