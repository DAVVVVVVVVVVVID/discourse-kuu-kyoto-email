# frozen_string_literal: true

Fabricator(:kuu_kyoto_user, from: :user) do
  email { sequence(:kuu_kyoto_email) { |i| "student#{i}@st.kyoto-u.ac.jp" } }

  after_create do |user|
    user.custom_fields[DiscourseKuuKyotoEmail::KyotoEmail::EMAIL_FIELD] = user.email
    user.custom_fields[
      DiscourseKuuKyotoEmail::KyotoEmail::VERIFIED_AT_FIELD
    ] = user.created_at.iso8601
    user.save_custom_fields
  end
end
