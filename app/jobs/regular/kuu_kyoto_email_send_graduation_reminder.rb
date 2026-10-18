# frozen_string_literal: true

module Jobs
  class KuuKyotoEmailSendGraduationReminder < ::Jobs::Base
    def execute(args)
      user = User.find_by(id: args[:user_id])
      return if user.nil? || DiscourseKuuKyotoEmail::KyotoEmail.personal_email?(user)

      message = DiscourseKuuKyotoEmail::ReminderMailer.graduation_reminder(user)
      Email::Sender.new(message, :kuu_kyoto_email_graduation_reminder, user).send
    end
  end
end
