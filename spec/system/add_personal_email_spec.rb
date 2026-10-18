# frozen_string_literal: true

RSpec.describe "Add personal email" do
  fab!(:user, :kuu_kyoto_user)

  let(:bind_modal) { PageObjects::Modals::KuuKyotoEmailBind.new }
  let(:banner) { PageObjects::Components::KuuKyotoEmailBanner.new }
  let(:preferences) { PageObjects::Components::KuuKyotoEmailPreferences.new }
  let!(:kyoto_email) { user.email }

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
    Jobs.run_immediately!
    sign_in(user)
  end

  it "lets a Kyoto user add a personal email from the first prompt" do
    visit("/")
    expect(bind_modal).to be_open
    bind_modal.bind_now

    find("#change-email").fill_in(with: "taro@example.com")
    find(".save-button button").click

    wait_for { ActionMailer::Base.deliveries.any? { |mail| mail.to == ["taro@example.com"] } }
    mail = ActionMailer::Base.deliveries.find { |delivery| delivery.to == ["taro@example.com"] }
    visit(mail.body.to_s[%r{/u/confirm-new-email/\S+}, 0])
    find(".confirm-new-email .btn-primary").click
    find(".dialog-footer .btn-primary").click

    visit("/u/#{user.username}/preferences/account")
    expect(banner).to be_hidden
    expect(bind_modal).to be_closed
    expect(preferences).to have_kyoto_email(kyoto_email)
    expect(preferences).to have_no_primary_warning
    expect(preferences).to have_locked_email(kyoto_email)
  end

  it "lets the user put off adding a personal email" do
    visit("/")
    bind_modal.later
    expect(banner).to be_visible

    banner.snooze
    expect(banner).to be_hidden

    page.refresh
    expect(banner).to be_hidden
    expect(bind_modal).to be_closed

    visit("/u/#{user.username}/preferences/account")
    expect(preferences).to have_kyoto_email(kyoto_email)
    expect(preferences).to have_primary_warning
  end
end
