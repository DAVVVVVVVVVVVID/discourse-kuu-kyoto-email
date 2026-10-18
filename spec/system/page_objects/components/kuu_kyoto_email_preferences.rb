# frozen_string_literal: true

module PageObjects
  module Components
    # 偏好设置 → 账户里的邮箱区
    class KuuKyotoEmailPreferences < PageObjects::Components::Base
      NOTE_SELECTOR = ".kuu-kyoto-email-note"

      def has_personal_email_note?(email)
        has_css?(
          "#{NOTE_SELECTOR} .kuu-kyoto-email-note__personal",
          text: I18n.t("js.kuu_kyoto_email.preferences.personal_email", email:),
        )
      end

      def has_bind_button?
        has_css?("#{NOTE_SELECTOR} .kuu-kyoto-email-note__bind")
      end

      def has_locked_email?(email)
        row = open_email_actions(email)
        row.has_css?(".select-kit-row[data-value='kuuKyotoEmailLocked']") &&
          row.has_no_css?(".select-kit-row[data-value='destroyEmail']")
      end

      private

      def open_email_actions(email)
        row = find(".pref-email .row.email", text: email)
        row.find(".email-dropdown .select-kit-header").click
        row
      end
    end
  end
end
