# frozen_string_literal: true

module Jobs
  # 毕业季提醒：京大邮箱还能收信时，提醒没绑定常用邮箱的人去绑定。
  # 每小时跑一次，错过一次也能补上；每人每个提醒日只发一封
  class KuuKyotoEmailGraduationReminder < ::Jobs::Scheduled
    every 1.hour

    TIMEZONE = "Asia/Tokyo"
    SEND_FROM_HOUR = 10

    def execute(_args)
      return if !SiteSetting.kuu_kyoto_email_enabled

      now = Time.zone.now.in_time_zone(TIMEZONE)
      return if now.hour < SEND_FROM_HOUR
      if SiteSetting.kuu_kyoto_email_reminder_dates.split("|").exclude?(now.strftime("%m-%d"))
        return
      end

      today = now.to_date.iso8601
      DiscourseKuuKyotoEmail::KyotoEmail.reminder_recipients.each do |user|
        next if user.custom_fields[DiscourseKuuKyotoEmail::KyotoEmail::REMINDED_ON_FIELD] == today

        user.custom_fields[DiscourseKuuKyotoEmail::KyotoEmail::REMINDED_ON_FIELD] = today
        user.save_custom_fields
        Jobs.enqueue(:kuu_kyoto_email_send_graduation_reminder, user_id: user.id)
      end
    end
  end
end
