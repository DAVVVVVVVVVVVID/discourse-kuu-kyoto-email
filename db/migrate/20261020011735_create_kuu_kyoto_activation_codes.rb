# frozen_string_literal: true
class CreateKuuKyotoActivationCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :kuu_kyoto_activation_codes do |t|
      t.integer :user_id, null: false
      t.string :code_hash, null: false
      t.integer :failed_attempts, null: false, default: 0
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :kuu_kyoto_activation_codes, :user_id, unique: true
  end
end
