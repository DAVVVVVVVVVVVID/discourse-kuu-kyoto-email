# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  module UserNotificationsExtension
    def signup(user, opts = {})
      return super if !ActivationCodeMail.applies?(user)

      kuu_activation_code_email(user)
    end

    def activation_reminder(user, opts = {})
      return super if !ActivationCodeMail.applies?(user)

      kuu_activation_code_email(user)
    end

    private

    def kuu_activation_code_email(user)
      code = ActivationCode.issue!(user)
      message =
        build_email(
          user.email,
          template: "kuu_kyoto_email.activation_code_mailer",
          locale: user_locale(user),
          activation_code: code,
          ttl_minutes: SiteSetting.kuu_kyoto_email_activation_code_ttl_minutes,
        )
      message.header[ActivationCodeMail::MARKER_HEADER] = "1"
      message
    end
  end
end
