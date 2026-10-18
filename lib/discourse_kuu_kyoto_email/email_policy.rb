# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  # 什么情况下允许非京大域名的邮箱。core 的 EmailValidator.allowed? 只在 allow 包住的代码里放宽
  module EmailPolicy
    STATE_KEY = :kuu_kyoto_email_non_kyoto_allowed

    # 以后的「通过指定邀请链接注册」在这里加一种 via
    def self.non_kyoto_allowed?(user:, via:)
      case via
      when :add_email
        user.present? && user.active? && !user.staged?
      else
        false
      end
    end

    def self.allow(user:, via:)
      previous = ActiveSupport::IsolatedExecutionState[STATE_KEY]
      ActiveSupport::IsolatedExecutionState[STATE_KEY] = non_kyoto_allowed?(user:, via:)
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[STATE_KEY] = previous
    end

    # 只放宽白名单；设了 allowed_email_domains 时 core 不看 blocked_email_domains，所以这里自己查
    def self.allows?(email)
      return false if !SiteSetting.kuu_kyoto_email_enabled
      return false if !ActiveSupport::IsolatedExecutionState[STATE_KEY]
      return false if KyotoEmail.domain?(email)

      blocked = SiteSetting.blocked_email_domains
      blocked.blank? || !EmailValidator.email_in_restriction_setting?(blocked, email)
    end
  end
end
