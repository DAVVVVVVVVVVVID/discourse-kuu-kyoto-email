# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  # 注册激活用的 6 位激活码，每个账号同时只有一个。
  # 校验用 HMAC（6 位数字只有一百万种，不加密钥的哈希拿到库就能穷举）；
  # 另存一份用服务器密钥加密的原码，重新发送时才能再发同一个码
  class ActivationCode < ActiveRecord::Base
    self.table_name = "kuu_kyoto_activation_codes"

    MAX_FAILED_ATTEMPTS = 5

    belongs_to :user

    # 现有的码还能用就再发同一个（有效期重新计算，输错次数不清零），否则换新码。
    # 第一封信晚到时，用户等不及点了重发，手里的码也还能用
    def self.issue!(user)
      now = Time.zone.now
      expires_at = SiteSetting.kuu_kyoto_email_activation_code_ttl_minutes.minutes.from_now

      if (code = reusable_code(user))
        where(user_id: user.id).update_all(expires_at:, updated_at: now)
        return code
      end

      code = SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
      upsert(
        {
          user_id: user.id,
          code_hash: digest(user, code),
          encrypted_code: encryptor.encrypt_and_sign(code),
          failed_attempts: 0,
          expires_at:,
          created_at: now,
          updated_at: now,
        },
        unique_by: :user_id,
      )
      code
    end

    def self.valid_for?(user)
      reusable_code(user).present?
    end

    # 码绑定在发信时的邮箱上：用户在等待页改了邮箱，旧地址收到的码就不再有效
    def self.reusable_code(user)
      record = find_by(user_id: user.id)
      return if record.nil?
      return if record.expires_at <= Time.zone.now
      return if record.failed_attempts >= MAX_FAILED_ATTEMPTS
      return if record.encrypted_code.blank?

      code = encryptor.decrypt_and_verify(record.encrypted_code)
      if code && ActiveSupport::SecurityUtils.secure_compare(record.code_hash, digest(user, code))
        code
      end
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end

    def self.encryptor
      key = Rails.application.key_generator.generate_key("kuu-kyoto-activation-code", 32)
      ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm")
    end

    # 返回 :ok、:invalid、:expired、:locked 或 :missing。
    # 先原子地占用一次尝试再比对，并发请求也试不出第 6 次
    def self.verify(user, code)
      record = find_by(user_id: user.id)
      return :missing if record.nil?
      return :expired if record.expires_at <= Time.zone.now

      reserved =
        where(id: record.id).where("failed_attempts < ?", MAX_FAILED_ATTEMPTS).update_all(
          "failed_attempts = failed_attempts + 1",
        )
      return :locked if reserved == 0

      if ActiveSupport::SecurityUtils.secure_compare(
           record.code_hash,
           digest(user, code.to_s.strip),
         )
        record.destroy!
        :ok
      else
        record.failed_attempts + 1 >= MAX_FAILED_ATTEMPTS ? :locked : :invalid
      end
    end

    def self.digest(user, code)
      OpenSSL::HMAC.hexdigest(
        "SHA256",
        Rails.application.secret_key_base,
        "kuu-kyoto-activation-code:#{user.id}:#{Email.downcase(user.email.to_s)}:#{code}",
      )
    end
  end
end

# == Schema Information
#
# Table name: kuu_kyoto_activation_codes
#
#  id              :bigint           not null, primary key
#  code_hash       :string           not null
#  encrypted_code  :string
#  expires_at      :datetime         not null
#  failed_attempts :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_kuu_kyoto_activation_codes_on_user_id  (user_id) UNIQUE
#
