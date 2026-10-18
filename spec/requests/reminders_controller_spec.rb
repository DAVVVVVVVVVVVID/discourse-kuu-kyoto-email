# frozen_string_literal: true

RSpec.describe DiscourseKuuKyotoEmail::RemindersController do
  fab!(:user, :kuu_kyoto_user)

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
  end

  describe "#dismiss_prompt" do
    it "requires login" do
      post "/kuu-kyoto-email/prompt/dismiss.json"

      expect(response.status).to eq(403)
    end

    it "stops the prompt from showing again" do
      sign_in(user)

      post "/kuu-kyoto-email/prompt/dismiss.json"

      expect(response.status).to eq(204)
      expect(DiscourseKuuKyotoEmail::KyotoEmail.reminder_status(user.reload)).to include(
        prompt_dismissed: true,
      )
    end
  end

  describe "#snooze_banner" do
    it "hides the banner for the configured number of days" do
      SiteSetting.kuu_kyoto_email_banner_snooze_days = 5
      sign_in(user)

      freeze_time do
        post "/kuu-kyoto-email/banner/snooze.json"

        expect(response.status).to eq(200)
        expect(response.parsed_body["banner_snoozed_until"]).to eq(5.days.from_now.iso8601)
      end
    end
  end
end
