# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  # 账号上的京大认证邮箱：注册时用的 allowed_email_domains 域名邮箱，记在用户自定义字段里
  module KyotoEmail
    EMAIL_FIELD = "kuu_kyoto_email"
    VERIFIED_AT_FIELD = "kuu_kyoto_verified_at"

    def self.domain?(email)
      setting = SiteSetting.allowed_email_domains
      return false if setting.blank? || email.blank?

      EmailValidator.email_in_restriction_setting?(setting, email).present?
    end

    def self.for(user)
      return if user.nil?

      user.custom_fields[EMAIL_FIELD].presence
    end

    def self.verified_at(user)
      user.custom_fields[VERIFIED_AT_FIELD].presence
    end

    def self.kyoto_record?(user_email, email = user_email.email)
      kyoto_email = self.for(user_email.user)
      kyoto_email.present? && Email.downcase(email.to_s) == kyoto_email
    end

    def self.primary_kyoto?(user)
      kyoto_email = self.for(user)
      kyoto_email.present? && user.primary_email&.email == kyoto_email
    end

    def self.personal_email?(user)
      user.user_emails.any? { |user_email| !domain?(user_email.email) }
    end

    def self.record!(user, verified_at: Time.zone.now)
      return if self.for(user).present?

      email = user.primary_email&.email
      return if !domain?(email)

      user.custom_fields[EMAIL_FIELD] = email
      user.custom_fields[VERIFIED_AT_FIELD] = verified_at.iso8601
      user.save_custom_fields
    end

    def self.reassign!(user, email)
      if domain?(email)
        user.custom_fields[EMAIL_FIELD] = Email.downcase(email)
        user.save_custom_fields
      else
        clear!(user)
      end
    end

    def self.clear!(user)
      user.custom_fields.delete(EMAIL_FIELD)
      user.custom_fields.delete(VERIFIED_AT_FIELD)
      user.save_custom_fields(true)
    end

    def self.backfill!
      User
        .real
        .where(active: true, staged: false)
        .includes(:primary_email)
        .find_each { |user| record!(user, verified_at: user.created_at) }
    end

    # 触发时 core 已经把来源账号的邮箱都移到目标账号；自定义字段只在目标没有同名字段时才移，
    # 所以要从数据库读。目标原本就有京大邮箱时，来源的京大邮箱移过去也没有锁，直接释放
    def self.release_for_merge!(source_user, target_user)
      source_kyoto_email = stored_kyoto_email(source_user)
      target_kyoto_email = stored_kyoto_email(target_user)
      return if source_kyoto_email.blank? || target_kyoto_email.blank?
      return if source_kyoto_email == target_kyoto_email

      EmailGuard.allow do
        UserEmail.where(
          user_id: [source_user.id, target_user.id],
          email: source_kyoto_email,
        ).destroy_all
      end
      clear!(source_user)
    end

    def self.stored_kyoto_email(user)
      UserCustomField.where(user_id: user.id, name: EMAIL_FIELD).pick(:value).presence
    end

    # 京大邮箱延迟高、毕业后失效，常用邮箱一确认就接替它当主邮箱
    def self.promote_personal_email!(user, email)
      return if !primary_kyoto?(user) || domain?(email)

      new_primary = user.user_emails.find_by(email: Email.downcase(email))
      return if new_primary.nil?

      User.transaction do
        user.primary_email.update!(primary: false)
        new_primary.update!(primary: true)
      end
      user.reload
      DiscourseEvent.trigger(:user_updated, user, %w[email])
    end
  end
end
