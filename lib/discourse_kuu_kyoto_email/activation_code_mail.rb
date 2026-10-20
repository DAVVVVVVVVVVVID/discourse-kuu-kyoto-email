# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  # 京大邮箱（Microsoft 365）会先扫描邮件里的每个链接再放进收件箱，带链接的激活邮件要等好几分钟。
  # 所以京大邮箱收到的激活邮件只写激活码，一个链接都不放
  module ActivationCodeMail
    MARKER_HEADER = "X-Kuu-Activation-Code"

    def self.applies?(user)
      SiteSetting.kuu_kyoto_email_enabled && SiteSetting.kuu_kyoto_email_activation_code_enabled &&
        KyotoEmail.domain?(user.email)
    end

    # core 发信时还会套上带 Logo、页脚链接的 HTML 外框，这里把链接和图片都拿掉，只留文字
    def self.strip_links(styles, message)
      return if message.header[MARKER_HEADER].blank?

      message.header[MARKER_HEADER] = nil
      styles.fragment.css("a").each { |link| link.replace(link.children) }
      styles.fragment.css("img").each(&:remove)
    end
  end
end
