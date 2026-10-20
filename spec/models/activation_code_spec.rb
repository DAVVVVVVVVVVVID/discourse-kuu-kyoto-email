# frozen_string_literal: true

RSpec.describe DiscourseKuuKyotoEmail::ActivationCode do
  fab!(:user) { Fabricate(:user, email: "taro@st.kyoto-u.ac.jp", active: false) }

  before { enable_current_plugin }

  describe ".issue!" do
    it "returns a 6-digit code and stores only its hash" do
      code = described_class.issue!(user)

      expect(code).to match(/\A\d{6}\z/)
      record = described_class.find_by(user_id: user.id)
      expect(record.code_hash).not_to include(code)
      expect(record.code_hash).not_to eq(Digest::SHA256.hexdigest(code))
    end

    it "keeps only an encrypted copy of the code, unreadable without the server key" do
      code = described_class.issue!(user)

      row =
        DB.query_hash("SELECT * FROM kuu_kyoto_activation_codes WHERE user_id = ?", user.id).first
      expect(row.values.map(&:to_s).join(" ")).not_to include(code)
      expect(row["encrypted_code"]).to be_present
    end

    it "sends the same code again while it is still valid, restarting the timer but keeping the failed attempts" do
      SiteSetting.kuu_kyoto_email_activation_code_ttl_minutes = 30
      code = freeze_time { described_class.issue!(user) }
      wrong_code = code == "000000" ? "111111" : "000000"
      described_class.verify(user, wrong_code)

      resent_code = freeze_time(20.minutes.from_now) { described_class.issue!(user) }

      expect(resent_code).to eq(code)
      record = described_class.find_by(user_id: user.id)
      expect(record.failed_attempts).to eq(1)
      freeze_time(45.minutes.from_now) { expect(described_class.verify(user, code)).to eq(:ok) }
    end

    it "sends a new code once the old one has expired" do
      code = freeze_time { described_class.issue!(user) }

      new_code = freeze_time(31.minutes.from_now) { described_class.issue!(user) }

      expect(described_class.where(user_id: user.id).count).to eq(1)
      expect(described_class.verify(user, code)).to eq(new_code == code ? :ok : :invalid)
    end

    it "sends a new code once the old one is locked by wrong attempts" do
      code = described_class.issue!(user)
      wrong_code = code == "000000" ? "111111" : "000000"
      5.times { described_class.verify(user, wrong_code) }

      new_code = described_class.issue!(user)

      expect(described_class.verify(user, new_code)).to eq(:ok)
    end

    it "sends a new code after the user changes the email address" do
      code = described_class.issue!(user)
      user.primary_email.update!(email: "jiro@st.kyoto-u.ac.jp")

      expect(described_class.valid_for?(user.reload)).to eq(false)
      expect(described_class.verify(user, code)).to eq(:invalid)
    end
  end

  describe ".verify" do
    it "accepts the right code once" do
      code = described_class.issue!(user)

      expect(described_class.verify(user, code)).to eq(:ok)
      expect(described_class.verify(user, code)).to eq(:missing)
    end

    it "locks the code after 5 wrong attempts, even if the right code comes next" do
      code = described_class.issue!(user)
      wrong_code = code == "000000" ? "111111" : "000000"

      results = 5.times.map { described_class.verify(user, wrong_code) }

      expect(results).to eq(%i[invalid invalid invalid invalid locked])
      expect(described_class.verify(user, code)).to eq(:locked)
    end

    it "expires the code after the configured number of minutes" do
      SiteSetting.kuu_kyoto_email_activation_code_ttl_minutes = 30
      code = freeze_time { described_class.issue!(user) }

      freeze_time(29.minutes.from_now) { expect(described_class.verify(user, code)).to eq(:ok) }

      code = freeze_time { described_class.issue!(user) }
      freeze_time(30.minutes.from_now) do
        expect(described_class.verify(user, code)).to eq(:expired)
      end
    end
  end
end
