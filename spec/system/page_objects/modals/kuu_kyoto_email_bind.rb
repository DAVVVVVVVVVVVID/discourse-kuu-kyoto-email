# frozen_string_literal: true

module PageObjects
  module Modals
    # 第一次登录时提示绑定常用邮箱的弹窗
    class KuuKyotoEmailBind < PageObjects::Modals::Base
      MODAL_SELECTOR = ".kuu-kyoto-email-bind-modal"

      def initialize
        super(modal_selector: MODAL_SELECTOR)
      end

      def bind_now
        find("#{MODAL_SELECTOR} .kuu-kyoto-email-bind-modal__bind").click
      end

      def later
        find("#{MODAL_SELECTOR} .kuu-kyoto-email-bind-modal__later").click
      end
    end
  end
end
