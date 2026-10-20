# frozen_string_literal: true

# name: discourse-kuu-kyoto-email
# about: 京大邮箱只用于注册和身份认证：注册后绑定常用邮箱接收通知，京大邮箱锁定在账号上
# version: 0.0.1
# authors: DAVVVVVVVVVVVID
# url: https://github.com/DAVVVVVVVVVVVID/discourse-kuu-kyoto-email
# required_version: 2026.1.0

enabled_site_setting :kuu_kyoto_email_enabled

register_asset "stylesheets/common/kuu-kyoto-email.scss"

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
    UserNotifications.prepend(DiscourseKuuKyotoEmail::UserNotificationsExtension)
  end

  register_modifier(:email_renderer_html) do |styles, message|
    DiscourseKuuKyotoEmail::ActivationCodeMail.strip_links(styles, message)
    styles
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

  on(:user_destroyed) do |user|
    DiscourseKuuKyotoEmail::ActivationCode.where(user_id: user.id).delete_all
  end

  on(:merging_users) do |source_user, target_user|
    DiscourseKuuKyotoEmail::KyotoEmail.release_for_merge!(source_user, target_user)
  end

  on_enabled_change { |_old_value, new_value| Jobs.enqueue(:kuu_kyoto_email_backfill) if new_value }

  # 前端据此认出邮箱列表里哪个是京大邮箱，不必为了标签另外暴露每个人的邮箱
  add_to_serializer(:site, :kuu_kyoto_email_domains) do
    SiteSetting.allowed_email_domains.split("|").compact_blank
  end

  add_to_serializer(
    :current_user,
    :kuu_kyoto_email_status,
    include_condition: -> { DiscourseKuuKyotoEmail::KyotoEmail.for(object).present? },
  ) { DiscourseKuuKyotoEmail::KyotoEmail.reminder_status(object) }

  add_to_serializer(
    :admin_detailed_user,
    :kuu_kyoto_email,
    include_condition: -> { DiscourseKuuKyotoEmail::KyotoEmail.for(object).present? },
  ) do
    {
      verified_at: DiscourseKuuKyotoEmail::KyotoEmail.verified_at(object),
      has_personal_email: DiscourseKuuKyotoEmail::KyotoEmail.personal_email?(object),
    }
  end
end
