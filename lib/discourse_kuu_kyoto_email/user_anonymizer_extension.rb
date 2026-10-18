# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  # 匿名化等同于注销：京大邮箱跟着释放
  module UserAnonymizerExtension
    def make_anonymous
      return super if !SiteSetting.kuu_kyoto_email_enabled

      result = EmailGuard.allow { super }
      KyotoEmail.clear!(@user)
      result
    end
  end
end
