# frozen_string_literal: true

RSpec.describe SiteSerializer do
  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
  end

  it "exposes the Kyoto email domains" do
    json = described_class.new(Site.new(Guardian.new), scope: Guardian.new, root: false).as_json

    expect(json[:kuu_kyoto_email_domains]).to eq(["st.kyoto-u.ac.jp"])
  end
end
