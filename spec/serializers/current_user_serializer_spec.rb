# frozen_string_literal: true

RSpec.describe CurrentUserSerializer do
  fab!(:user, :kuu_kyoto_user)
  fab!(:admin)

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
  end

  it "tells a Kyoto user without a personal email to add one" do
    json = described_class.new(user, scope: user.guardian, root: false).as_json

    expect(json[:kuu_kyoto_email_status]).to eq(
      kyoto_email: user.email,
      verified_at: user.created_at.iso8601,
      primary_is_kyoto: true,
      needs_personal_email: true,
      pending_email: nil,
      prompt_dismissed: false,
      banner_snoozed_until: nil,
    )
  end

  it "shows the personal email waiting for confirmation" do
    EmailUpdater.new(guardian: user.guardian, user:).change_to("taro@example.com", add: true)

    json = described_class.new(user.reload, scope: user.guardian, root: false).as_json

    expect(json[:kuu_kyoto_email_status]).to include(
      needs_personal_email: true,
      pending_email: "taro@example.com",
    )
  end

  it "leaves accounts without a Kyoto email out" do
    json = described_class.new(admin, scope: admin.guardian, root: false).as_json

    expect(json).not_to have_key(:kuu_kyoto_email_status)
  end
end
