# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  # 京大邮箱的锁只对本人生效：管理员在别人的偏好设置里照样能删、能设为主邮箱
  module UsersControllerExtension
    def destroy_email
      return super if !SiteSetting.kuu_kyoto_email_enabled || current_user.nil?

      user = fetch_user_from_params
      kyoto_email = KyotoEmail.for(user)
      return super if kyoto_email.blank? || Email.downcase(params[:email].to_s) != kyoto_email

      return kuu_render_kyoto_email_locked if !kuu_staff_acting_on_other_user?(user)

      EmailGuard.allow { super }
      KyotoEmail.clear!(user) if !user.user_emails.exists?(email: kyoto_email)
    end

    def update_primary_email
      return super if !SiteSetting.kuu_kyoto_email_enabled || current_user.nil?

      user = fetch_user_from_params
      if KyotoEmail.domain?(params[:email].to_s) && !kuu_staff_acting_on_other_user?(user)
        return kuu_render_kyoto_email_locked
      end

      super
    end

    private

    def kuu_staff_acting_on_other_user?(user)
      current_user.staff? && current_user != user
    end

    def kuu_render_kyoto_email_locked
      render_json_error(I18n.t("kuu_kyoto_email.errors.kyoto_email_locked"), status: 403)
    end
  end
end
