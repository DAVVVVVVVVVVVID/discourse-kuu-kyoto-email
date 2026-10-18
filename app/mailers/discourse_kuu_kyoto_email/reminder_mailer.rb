# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  class ReminderMailer < ::ActionMailer::Base
    include Email::BuildEmailHelper

    def graduation_reminder(user)
      build_email(
        user.email,
        template: "kuu_kyoto_email.graduation_reminder_mailer",
        locale: user.effective_locale,
        username: user.username,
        bind_url: "#{Discourse.base_url}/u/#{user.username_lower}/preferences/email?new=1",
      )
    end
  end
end
