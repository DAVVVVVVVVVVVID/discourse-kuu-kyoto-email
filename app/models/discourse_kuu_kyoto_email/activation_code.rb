# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  # 注册激活用的 6 位激活码。每个账号同时只有一个有效的码，库里只存 HMAC：
  # 6 位数字只有一百万种，不加密钥的哈希拿到库就能直接穷举
  class ActivationCode < ActiveRecord::Base
    self.table_name = "kuu_kyoto_activation_codes"

    MAX_FAILED_ATTEMPTS = 5

    belongs_to :user

    def self.issue!(user)
      code = SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
      now = Time.zone.now
      upsert(
        {
          user_id: user.id,
          code_hash: digest(user.id, code),
          failed_attempts: 0,
          expires_at: SiteSetting.kuu_kyoto_email_activation_code_ttl_minutes.minutes.from_now,
          created_at: now,
          updated_at: now,
        },
        unique_by: :user_id,
      )
      code
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
           digest(user.id, code.to_s.strip),
         )
        record.destroy!
        :ok
      else
        record.failed_attempts + 1 >= MAX_FAILED_ATTEMPTS ? :locked : :invalid
      end
    end

    def self.digest(user_id, code)
      OpenSSL::HMAC.hexdigest(
        "SHA256",
        Rails.application.secret_key_base,
        "kuu-kyoto-activation-code:#{user_id}:#{code}",
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
