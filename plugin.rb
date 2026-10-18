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

after_initialize do
  reloadable_patch do
    EmailValidator.singleton_class.prepend(DiscourseKuuKyotoEmail::EmailValidatorExtension)
    EmailUpdater.prepend(DiscourseKuuKyotoEmail::EmailUpdaterExtension)
    UsersController.prepend(DiscourseKuuKyotoEmail::UsersControllerExtension)
    UserAnonymizer.prepend(DiscourseKuuKyotoEmail::UserAnonymizerExtension)
  end

  add_model_callback(:user_email, :before_update) do
    DiscourseKuuKyotoEmail::EmailGuard.before_update(self)
  end

  add_model_callback(:user_email, :before_destroy) do
    DiscourseKuuKyotoEmail::EmailGuard.before_destroy(self)
  end

  on(:user_confirmed_email) do |user, scope|
    DiscourseKuuKyotoEmail::KyotoEmail.record!(user) if scope == EmailToken.scopes[:signup]
  end

  # 管理员建的号、邀请链接注册的号等创建时就已激活，不会再走邮件激活
  on(:user_created) { |user| DiscourseKuuKyotoEmail::KyotoEmail.record!(user) if user.active? }

  on(:merging_users) do |source_user, target_user|
    DiscourseKuuKyotoEmail::KyotoEmail.release_for_merge!(source_user, target_user)
  end

  on_enabled_change { |_old_value, new_value| Jobs.enqueue(:kuu_kyoto_email_backfill) if new_value }
end
