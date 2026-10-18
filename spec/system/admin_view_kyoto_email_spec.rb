# frozen_string_literal: true

RSpec.describe "Admin views Kyoto email" do
  fab!(:admin)
  fab!(:user, :kuu_kyoto_user)

  let(:admin_user_page) { PageObjects::Pages::AdminUser.new }

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
    sign_in(admin)
  end

  it "shows the admin the Kyoto email after they reveal the user's emails" do
    admin_user_page.visit(user)

    expect(page).to have_css(
      ".kuu-kyoto-email-admin__email",
      text: I18n.t("js.kuu_kyoto_email.admin.reveal_hint"),
    )
    expect(page).to have_css(
      ".kuu-kyoto-email-admin-personal .value",
      text: I18n.t("js.kuu_kyoto_email.admin.personal_email_missing"),
    )

    find(".display-row.email .btn").click

    expect(page).to have_css(".kuu-kyoto-email-admin__email", text: user.email)
  end
end
