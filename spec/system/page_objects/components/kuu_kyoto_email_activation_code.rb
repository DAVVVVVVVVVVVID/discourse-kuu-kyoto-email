# frozen_string_literal: true

module PageObjects
  module Components
    # 等待页和「账号未激活」弹窗里的激活码输入框
    class KuuKyotoEmailActivationCode < PageObjects::Components::Base
      SELECTOR = ".kuu-kyoto-email-activation-code"

      def has_sent_to?(email)
        has_css?(
          "#{SELECTOR}__sent",
          text: I18n.t("js.kuu_kyoto_email.activation_code.sent", email:),
        )
      end

      def activate_with(code)
        find("#{SELECTOR} input[name='code']").fill_in(with: code)
        find("#{SELECTOR}__submit").click
        self
      end

      def resend
        find("#{SELECTOR}__resend").click
        self
      end

      def has_resend_countdown?
        has_css?("#{SELECTOR}__resend[disabled]", text: /\d+/)
      end

      def has_resend_available?
        has_css?(
          "#{SELECTOR}__resend:not([disabled])",
          exact_text: I18n.t("js.kuu_kyoto_email.activation_code.resend"),
        )
      end

      def has_resent_message?
        has_css?("#{SELECTOR}__resent")
      end

      def has_error?(message)
        has_css?("#{SELECTOR}__error", text: message)
      end
    end
  end
end
