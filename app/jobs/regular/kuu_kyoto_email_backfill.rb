# frozen_string_literal: true

module Jobs
  # 给插件打开之前（或关着期间）激活的京大邮箱账号补上京大认证邮箱
  class KuuKyotoEmailBackfill < ::Jobs::Base
    def execute(_args)
      return if !SiteSetting.kuu_kyoto_email_enabled

      DiscourseKuuKyotoEmail::KyotoEmail.backfill!
    end
  end
end
