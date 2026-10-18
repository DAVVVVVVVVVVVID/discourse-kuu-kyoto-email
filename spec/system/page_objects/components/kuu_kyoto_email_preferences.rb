# frozen_string_literal: true

module PageObjects
  module Components
    # 偏好设置 → 账户里的邮箱区
    class KuuKyotoEmailPreferences < PageObjects::Components::Base
      SECTION_SELECTOR = ".kuu-kyoto-email-section"

      def has_kyoto_email?(email)
        has_css?("#{SECTION_SELECTOR} .kuu-kyoto-email-section__address", text: email)
      end

      def has_primary_warning?
        has_css?("#{SECTION_SELECTOR} .kuu-kyoto-email-section__warning")
      end

      def has_no_primary_warning?
        has_no_css?("#{SECTION_SELECTOR} .kuu-kyoto-email-section__warning")
      end

      def has_no_kyoto_email_section?
        has_no_css?(SECTION_SELECTOR)
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
