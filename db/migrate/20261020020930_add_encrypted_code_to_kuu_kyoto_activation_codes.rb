# frozen_string_literal: true

# 旧行只有 HMAC，取不回原码，没法「重新发送同一个码」。线上只有几行，直接清空：
# 这些用户点「重新发送」会拿到新码。
# 新列允许为空：回滚到上一版时，旧代码插入的行不写这一列也不会报错
class AddEncryptedCodeToKuuKyotoActivationCodes < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM kuu_kyoto_activation_codes"
    add_column :kuu_kyoto_activation_codes, :encrypted_code, :string
  end

  def down
    remove_column :kuu_kyoto_activation_codes, :encrypted_code
  end
end
