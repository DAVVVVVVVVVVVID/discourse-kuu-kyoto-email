# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  class RemindersController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    def dismiss_prompt
      current_user.custom_fields[KyotoEmail::PROMPT_DISMISSED_FIELD] = Time.zone.now.iso8601
      current_user.save_custom_fields
      head :no_content
    end

    def snooze_banner
      snoozed_until = SiteSetting.kuu_kyoto_email_banner_snooze_days.days.from_now
      current_user.custom_fields[KyotoEmail::BANNER_SNOOZED_UNTIL_FIELD] = snoozed_until.iso8601
      current_user.save_custom_fields
      render json: { banner_snoozed_until: snoozed_until.iso8601 }
    end
  end
end
