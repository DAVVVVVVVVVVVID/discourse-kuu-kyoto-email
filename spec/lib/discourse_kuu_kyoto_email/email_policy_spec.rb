# frozen_string_literal: true

RSpec.describe DiscourseKuuKyotoEmail::EmailPolicy do
  fab!(:user, :kuu_kyoto_user)
  fab!(:inactive_user) { Fabricate(:user, active: false) }
  fab!(:staged_user, :staged)

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
  end

  describe ".non_kyoto_allowed?" do
    it "allows only active, non-staged accounts adding an email" do
      expect(described_class.non_kyoto_allowed?(user:, via: :add_email)).to eq(true)
      expect(described_class.non_kyoto_allowed?(user: inactive_user, via: :add_email)).to eq(false)
      expect(described_class.non_kyoto_allowed?(user: staged_user, via: :add_email)).to eq(false)
      expect(described_class.non_kyoto_allowed?(user:, via: :signup)).to eq(false)
    end
  end

  describe ".allow" do
    it "relaxes EmailValidator.allowed? only inside the block" do
      inside = described_class.allow(user:, via: :add_email) { EmailValidator.allowed?("a@b.com") }

      expect(inside).to eq(true)
      expect(EmailValidator.allowed?("a@b.com")).to eq(false)
    end

    it "keeps the restriction for accounts that may not add emails" do
      inside =
        described_class.allow(user: inactive_user, via: :add_email) do
          EmailValidator.allowed?("a@b.com")
        end

      expect(inside).to eq(false)
    end
  end
end
