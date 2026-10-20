# frozen_string_literal: true

RSpec.describe "Kyoto email lifecycle" do
  fab!(:kyoto_user, :kuu_kyoto_user)
  fab!(:admin)

  let!(:kyoto_email) { DiscourseKuuKyotoEmail::KyotoEmail.for(kyoto_user) }

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
  end

  def kyoto_email_of(user)
    DiscourseKuuKyotoEmail::KyotoEmail.for(user.reload)
  end

  describe "signing up" do
    it "records the Kyoto email when the account is activated" do
      user = Fabricate(:user, email: "new@st.kyoto-u.ac.jp", active: false)
      token = user.email_tokens.create!(email: user.email, scope: EmailToken.scopes[:signup])

      freeze_time { EmailToken.confirm(token.token, scope: EmailToken.scopes[:signup]) }

      expect(kyoto_email_of(user)).to eq("new@st.kyoto-u.ac.jp")
      expect(DiscourseKuuKyotoEmail::KyotoEmail.verified_at(user)).to eq(Time.zone.now.iso8601)
    end

    it "records the Kyoto email of an account created already active" do
      user = Fabricate(:user, email: "invited@st.kyoto-u.ac.jp", active: true)

      expect(kyoto_email_of(user)).to eq("invited@st.kyoto-u.ac.jp")
    end

    it "still only accepts Kyoto emails for new accounts" do
      expect(Fabricate.build(:user, email: "outsider@example.com")).not_to be_valid
    end
  end

  describe "the model guard" do
    it "stops other code paths from changing or deleting the Kyoto email" do
      record = kyoto_user.primary_email

      expect(record.update(email: "changed@st.kyoto-u.ac.jp")).to eq(false)
      expect(record.reload.email).to eq(kyoto_email)
      expect(record.destroy).to eq(false)
      expect(UserEmail.exists?(record.id)).to eq(true)
    end

    it "leaves accounts without a Kyoto email alone" do
      record = admin.primary_email
      record.skip_validate_email = true

      expect(record.update(email: "boss@example.com")).to eq(true)
    end
  end

  describe "deleting or anonymizing the account" do
    it "releases the Kyoto email and drops any activation code when the account is deleted" do
      DiscourseKuuKyotoEmail::ActivationCode.issue!(kyoto_user)

      UserDestroyer.new(admin).destroy(kyoto_user)

      expect(UserEmail.exists?(email: kyoto_email)).to eq(false)
      expect(DiscourseKuuKyotoEmail::ActivationCode.exists?(user_id: kyoto_user.id)).to eq(false)
    end

    it "releases the Kyoto email when the account is anonymized" do
      kyoto_user.user_emails.create!(email: "taro@example.com", skip_validate_email: true)
      DiscourseKuuKyotoEmail::KyotoEmail.promote_personal_email!(kyoto_user, "taro@example.com")

      UserAnonymizer.make_anonymous(kyoto_user, admin)

      expect(UserEmail.exists?(email: kyoto_email)).to eq(false)
      expect(kyoto_email_of(kyoto_user)).to be_nil
    end
  end

  describe "merging accounts" do
    it "releases the source's Kyoto email when the target already has one" do
      target = Fabricate(:kuu_kyoto_user)

      UserMerger.new(kyoto_user, target, admin).merge!

      expect(UserEmail.exists?(email: kyoto_email)).to eq(false)
      expect(kyoto_email_of(target)).to eq(target.email)
    end

    it "makes the source's Kyoto email the target's when the target has none" do
      UserMerger.new(kyoto_user, admin, admin).merge!

      admin.reload
      expect(admin.secondary_emails).to contain_exactly(kyoto_email)
      expect(kyoto_email_of(admin)).to eq(kyoto_email)
      expect(admin.user_emails.find_by(email: kyoto_email).destroy).to eq(false)
    end
  end

  describe "turning the plugin on" do
    it "backfills accounts activated while the plugin was off" do
      SiteSetting.kuu_kyoto_email_enabled = false
      user = Fabricate(:user, email: "earlier@st.kyoto-u.ac.jp", created_at: 1.year.ago)

      Jobs.run_immediately!
      SiteSetting.kuu_kyoto_email_enabled = true

      expect(kyoto_email_of(user)).to eq("earlier@st.kyoto-u.ac.jp")
      expect(DiscourseKuuKyotoEmail::KyotoEmail.verified_at(user)).to eq(user.created_at.iso8601)
      expect(kyoto_email_of(admin)).to be_nil
    end
  end
end
