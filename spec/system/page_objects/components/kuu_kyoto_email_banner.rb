# frozen_string_literal: true

module PageObjects
  module Components
    # 页面顶部「绑定常用邮箱」提示条
    class KuuKyotoEmailBanner < PageObjects::Components::Base
      SELECTOR = ".kuu-kyoto-email-banner"

      def visible?
        has_css?(SELECTOR)
      end

      def hidden?
        has_no_css?(SELECTOR)
      end

      def snooze
        find("#{SELECTOR} .kuu-kyoto-email-banner__close").click
      end
    end
  end
end
