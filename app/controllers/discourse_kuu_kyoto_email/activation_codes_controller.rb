# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  class ActivationCodesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    skip_before_action :redirect_to_login_if_required, :redirect_to_profile_if_required

    # 前端倒计时 60 秒，这里留几秒余量，免得按钮刚变亮就被拒
    RESEND_INTERVAL = 55.seconds

    def create
      raise Discourse::NotFound if !SiteSetting.kuu_kyoto_email_activation_code_enabled
      raise Discourse::InvalidAccess if current_user.present?

      login = params.require(:login).to_s.strip
      RateLimiter.new(nil, "kuu-activation-code-min-#{request.remote_ip}", 10, 1.minute).performed!
      RateLimiter.new(nil, "kuu-activation-code-hr-#{request.remote_ip}", 30, 1.hour).performed!
      RateLimiter.new(nil, "kuu-activation-code-login-#{login.downcase}", 10, 1.hour).performed!

      # 账号不存在和激活码不对给同样的回复，免得被用来试探哪些用户名或邮箱注册过
      user = User.find_by_username_or_email(login)
      return render_code_error(:invalid) if user.nil? || user.staged?
      if user.active?
        return render_json_error(I18n.t("kuu_kyoto_email.activation_code.already_active"))
      end

      result = ActivationCode.verify(user, params.require(:code))
      return render_code_error(result) if result != :ok

      activate(user)
    rescue RateLimiter::LimitExceeded
      render_json_error(I18n.t("rate_limiter.slow_down"), status: 429)
    end

    # 「账号未激活」弹窗打开时用。只认 core 在用户输对密码后记进 session 的账号，
    # 不接收用户名或邮箱，没法拿来探测别人的账号
    def status
      raise Discourse::NotFound if !SiteSetting.kuu_kyoto_email_activation_code_enabled

      RateLimiter.new(
        nil,
        "kuu-activation-code-status-#{request.remote_ip}",
        30,
        1.minute,
      ).performed!

      user_id = session[SessionController::ACTIVATE_USER_KEY]
      user = User.find_by(id: user_id.to_i) if user_id.present?
      render json: { has_valid_code: user.present? && ActivationCode.valid_for?(user) }
    rescue RateLimiter::LimitExceeded
      render_json_error(I18n.t("rate_limiter.slow_down"), status: 429)
    end

    # 「激活」旁边的「重新发送」。core 的 send_activation_email 发完会清掉 session 里的账号，
    # 第二次点就被拒，刷新页面后也认不出是谁；这里沿用它的限速和规则，但保留 session
    def resend
      raise Discourse::NotFound if !SiteSetting.kuu_kyoto_email_activation_code_enabled
      raise Discourse::InvalidAccess if current_user.present? || SiteSetting.must_approve_users?

      user_id = session[SessionController::ACTIVATE_USER_KEY]
      user = User.find_by(id: user_id.to_i) if user_id.present?
      raise Discourse::InvalidAccess if user.nil? || user.staged?

      RateLimiter.new(nil, "activate-hr-#{request.remote_ip}", 30, 1.hour).performed!
      RateLimiter.new(nil, "activate-min-#{request.remote_ip}", 6, 1.minute).performed!
      RateLimiter.new(nil, "kuu-activation-code-resend-#{user.id}", 1, RESEND_INTERVAL).performed!

      if user.active?
        return render_json_error(I18n.t("kuu_kyoto_email.activation_code.already_active"))
      end

      email_token = user.email_tokens.create!(email: user.email, scope: EmailToken.scopes[:signup])
      EmailToken.enqueue_signup_email(email_token, to_address: user.email)
      render json: success_json
    rescue RateLimiter::LimitExceeded
      render_json_error(I18n.t("rate_limiter.slow_down"), status: 429)
    end

    private

    # 和点激活链接（UsersController#perform_account_activation）的效果一样
    def activate(user)
      email_token = user.email_tokens.create!(email: user.email, scope: EmailToken.scopes[:signup])
      user = EmailToken.confirm(email_token.token, scope: EmailToken.scopes[:signup])
      return render_code_error(:invalid) if user.nil?

      session.delete(SessionController::ACTIVATE_USER_KEY)

      if !user.guardian.can_access_forum?
        return render json: success_json.merge(needs_approval: true)
      end

      user.enqueue_welcome_message("welcome_user") if user.send_welcome_message
      log_on_user(user, replay_anonymous_action: true)
      redirect_to = Wizard.user_requires_completion?(user) ? wizard_path : path("/")
      render json: success_json.merge(needs_approval: false, redirect_to:)
    end

    def render_code_error(result)
      render_json_error(I18n.t("kuu_kyoto_email.activation_code.#{result}"))
    end
  end
end
