# frozen_string_literal: true

RSpec.describe Jobs::KuuKyotoEmailGraduationReminder do
  fab!(:student, :kuu_kyoto_user)
  fab!(:student_with_personal_email, :kuu_kyoto_user)
  fab!(:suspended_student) { Fabricate(:kuu_kyoto_user, suspended_till: 1.year.from_now) }
  fab!(:bouncing_student, :kuu_kyoto_user)
  fab!(:admin)

  # 2027-01-15 10:00 日本时间
  let(:reminder_time) { Time.utc(2027, 1, 15, 1, 0) }

  before do
    enable_current_plugin
    SiteSetting.allowed_email_domains = "st.kyoto-u.ac.jp"
    SiteSetting.kuu_kyoto_email_reminder_dates = "01-15|02-15"
    student_with_personal_email.user_emails.create!(
      email: "taro@example.com",
      skip_validate_email: true,
    )
    bouncing_student.user_stat.update!(bounce_score: SiteSetting.bounce_score_threshold)
    Jobs.run_immediately!
  end

  def reminded_addresses
    ActionMailer::Base.deliveries.flat_map(&:to)
  end

  describe "#execute" do
    it "emails only Kyoto students who can still receive mail and have no personal email" do
      freeze_time(reminder_time) { described_class.new.execute({}) }

      expect(reminded_addresses).to contain_exactly(student.email)
      expect(ActionMailer::Base.deliveries.first.body.to_s).to include(
        "/u/#{student.username_lower}/preferences/email?new=1",
      )
    end

    it "sends one email per student per reminder date" do
      freeze_time(reminder_time) { described_class.new.execute({}) }
      freeze_time(reminder_time + 3.hours) { described_class.new.execute({}) }

      expect(reminded_addresses).to contain_exactly(student.email)
    end

    it "waits until the morning in Japan on a reminder date" do
      freeze_time(reminder_time - 2.hours) { described_class.new.execute({}) }
      freeze_time(reminder_time + 1.day) { described_class.new.execute({}) }

      expect(reminded_addresses).to be_empty
    end
  end
end
