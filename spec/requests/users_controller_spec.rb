# frozen_string_literal: true

RSpec.describe UsersController do
  fab!(:user, :kuu_kyoto_user)
  fab!(:admin)

  let!(:kyoto_email) { DiscourseKuuKyotoEmail::KyotoEmail.for(user) }

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
    user.user_emails.create!(email: "taro@example.com", skip_validate_email: true)
    DiscourseKuuKyotoEmail::KyotoEmail.promote_personal_email!(user, "taro@example.com")
  end

  describe "#destroy_email" do
    it "rejects the user removing their Kyoto email" do
      sign_in(user)

      delete "/u/#{user.username}/preferences/email.json", params: { email: kyoto_email }

      expect(response.status).to eq(403)
      expect(response.parsed_body["errors"]).to contain_exactly(
        I18n.t("kuu_kyoto_email.errors.kyoto_email_locked"),
      )
      expect(user.reload.secondary_emails).to contain_exactly(kyoto_email)
    end

    it "lets the user remove other secondary emails" do
      user.user_emails.create!(email: "extra@example.com", skip_validate_email: true)
      sign_in(user)

      delete "/u/#{user.username}/preferences/email.json", params: { email: "extra@example.com" }

      expect(response.status).to eq(200)
      expect(user.reload.secondary_emails).to contain_exactly(kyoto_email)
    end

    it "lets an admin remove someone's Kyoto email and forgets it" do
      sign_in(admin)

      delete "/u/#{user.username}/preferences/email.json", params: { email: kyoto_email }

      expect(response.status).to eq(200)
      user.reload
      expect(user.secondary_emails).to be_empty
      expect(DiscourseKuuKyotoEmail::KyotoEmail.for(user)).to be_nil
    end
  end

  describe "#update_primary_email" do
    it "rejects the user making their Kyoto email primary again" do
      sign_in(user)

      put "/u/#{user.username}/preferences/primary-email.json", params: { email: kyoto_email }

      expect(response.status).to eq(403)
      expect(user.reload.email).to eq("taro@example.com")
    end

    it "lets the user switch between personal emails" do
      user.user_emails.create!(email: "extra@example.com", skip_validate_email: true)
      sign_in(user)

      put "/u/#{user.username}/preferences/primary-email.json",
          params: {
            email: "extra@example.com",
          }

      expect(response.status).to eq(200)
      expect(user.reload.email).to eq("extra@example.com")
    end

    it "lets an admin make someone's Kyoto email primary" do
      sign_in(admin)

      put "/u/#{user.username}/preferences/primary-email.json", params: { email: kyoto_email }

      expect(response.status).to eq(200)
      expect(user.reload.email).to eq(kyoto_email)
    end
  end
end
