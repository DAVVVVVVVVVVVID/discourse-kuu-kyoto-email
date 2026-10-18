# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  # 模型层的最后一道保险：只有 allow 包住的代码（管理员操作、注销、合并账号）能改写或删除京大邮箱记录。
  # 删账号时的级联删除另外放行
  module EmailGuard
    STATE_KEY = :kuu_kyoto_email_guard_disabled

    def self.allow
      previous = ActiveSupport::IsolatedExecutionState[STATE_KEY]
      ActiveSupport::IsolatedExecutionState[STATE_KEY] = true
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[STATE_KEY] = previous
    end

    def self.allowed?
      !!ActiveSupport::IsolatedExecutionState[STATE_KEY]
    end

    def self.before_update(user_email)
      return if allowed? || !user_email.will_save_change_to_email?
      return if !KyotoEmail.kyoto_record?(user_email, user_email.email_in_database)

      reject(user_email)
    end

    def self.before_destroy(user_email)
      return if allowed? || user_email.destroyed_by_association
      return if !KyotoEmail.kyoto_record?(user_email, user_email.email_in_database)

      reject(user_email)
    end

    def self.reject(user_email)
      user_email.errors.add(:email, I18n.t("kuu_kyoto_email.errors.kyoto_email_locked"))
      throw :abort
    end
  end
end
