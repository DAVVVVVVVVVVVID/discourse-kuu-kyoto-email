# frozen_string_literal: true

RSpec.describe AdminDetailedUserSerializer do
  fab!(:user, :kuu_kyoto_user)
  fab!(:admin)

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
  end

  it "gives admins the verification time without the address itself" do
    json = described_class.new(user, scope: admin.guardian, root: false).as_json

    expect(json[:kuu_kyoto_email]).to eq(
      verified_at: user.created_at.iso8601,
      has_personal_email: false,
    )
    expect(json.to_s).not_to include(user.email)
  end
end
