# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  module EmailUpdaterExtension
    def change_to(email, add: false)
      return super if !SiteSetting.kuu_kyoto_email_enabled

      @guardian.ensure_can_edit_email!(@user)

      if !kuu_staff_acting_on_other_user?
        if KyotoEmail.domain?(Email.downcase(email.to_s.strip))
          errors.add(:base, I18n.t("kuu_kyoto_email.errors.kyoto_domain_not_allowed"))
          return
        end

        # core 会就地改写主邮箱那条记录，京大邮箱是主邮箱时只能「添加」
        if !add && KyotoEmail.primary_kyoto?(@user)
          errors.add(:base, I18n.t("kuu_kyoto_email.errors.kyoto_email_locked"))
          return
        end
      end

      EmailPolicy.allow(user: @user, via: :add_email) { super }
    end

    def update_user_email(old_email, new_email)
      return super if !SiteSetting.kuu_kyoto_email_enabled

      replaces_kyoto = old_email.present? && Email.downcase(old_email) == KyotoEmail.for(@user)
      requested_by_staff = @change_req&.requested_by&.staff? && !@change_req.requested_by_self?

      # 插件打开前提交的「修改」申请：保留京大邮箱，当作添加
      old_email = nil if replaces_kyoto && !requested_by_staff

      EmailPolicy.allow(user: @user, via: :add_email) do
        if replaces_kyoto && requested_by_staff
          EmailGuard.allow { super(old_email, new_email) }
          KyotoEmail.reassign!(@user, new_email)
        else
          super(old_email, new_email)
        end
      end

      KyotoEmail.promote_personal_email!(@user, new_email)
    end

    private

    def kuu_staff_acting_on_other_user?
      @guardian.is_staff? && @guardian.user != @user
    end
  end
end
