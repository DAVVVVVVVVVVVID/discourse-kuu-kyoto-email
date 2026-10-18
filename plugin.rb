# frozen_string_literal: true

# name: discourse-kuu-kyoto-email
# about: 京大邮箱只用于注册和身份认证：注册后绑定常用邮箱接收通知，京大邮箱锁定在账号上
# version: 0.0.1
# authors: DAVVVVVVVVVVVID
# url: https://github.com/DAVVVVVVVVVVVID/discourse-kuu-kyoto-email
# required_version: 2026.1.0

enabled_site_setting :kuu_kyoto_email_enabled

module ::DiscourseKuuKyotoEmail
  PLUGIN_NAME = "discourse-kuu-kyoto-email"
end

require_relative "lib/discourse_kuu_kyoto_email/engine"

after_initialize {}
