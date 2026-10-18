# frozen_string_literal: true

RSpec.describe "Sign up with Kyoto email" do
  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
  end

  let(:hint) { I18n.t("js.kuu_kyoto_email.signup_hint", domains: "@st.kyoto-u.ac.jp") }

  it "tells visitors to sign up with their Kyoto email in the code sign-up flow" do
    visit("/signup")

    expect(page).to have_css(".kuu-kyoto-email-signup-hint", text: hint)
  end

  it "tells visitors the same in the classic sign-up form" do
    SiteSetting.enable_local_logins_via_code = false

    visit("/signup")

    expect(page).to have_css(".kuu-kyoto-email-signup-hint", text: hint)
  end
end
