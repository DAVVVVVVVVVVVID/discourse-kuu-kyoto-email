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

    it "replaces the previous code" do
      old_code = described_class.issue!(user)
      new_code = described_class.issue!(user)

      expect(described_class.where(user_id: user.id).count).to eq(1)
      expect(described_class.verify(user, old_code)).to eq(old_code == new_code ? :ok : :invalid)
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
