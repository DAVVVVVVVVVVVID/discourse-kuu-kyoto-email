# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  class ActivationCodesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    skip_before_action :redirect_to_login_if_required, :redirect_to_profile_if_required

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
