class Admin::ApplicationSettingsController < Admin::ApplicationController
  before_action :set_application_setting

  def show
  end

  def update
    if @application_setting.update_attributes(application_setting_params)
      redirect_to admin_application_settings_path,
        notice: '应用设置保存成功'
    else
      render :show
    end
  end

  def reset_runners_token
    @application_setting.reset_runners_registration_token!
    flash[:notice] = '已生成新的 runner 注册授权码！'
    redirect_to admin_runners_path
  end

  def reset_health_check_token
    @application_setting.reset_health_check_access_token!
    flash[:notice] = '已生成新的健康检查访问授权码！'
    redirect_to :back
  end

  def clear_repository_check_states
    RepositoryCheck::ClearWorker.perform_async

    redirect_to(
      admin_application_settings_path,
      notice: '已开始取消所有版本仓库状态检查。'
    )
  end

  private

  def set_application_setting
    @application_setting = ApplicationSetting.current
  end

  def application_setting_params
    restricted_levels = params[:application_setting][:restricted_visibility_levels]
    if restricted_levels.nil?
      params[:application_setting][:restricted_visibility_levels] = []
    else
      restricted_levels.map! do |level|
        level.to_i
      end
    end

    import_sources = params[:application_setting][:import_sources]
    if import_sources.nil?
      params[:application_setting][:import_sources] = []
    else
      import_sources.map! do |source|
        source.to_str
      end
    end

    enabled_oauth_sign_in_sources = params[:application_setting].delete(:enabled_oauth_sign_in_sources)

    params[:application_setting][:disabled_oauth_sign_in_sources] =
      AuthHelper.button_based_providers.map(&:to_s) -
      Array(enabled_oauth_sign_in_sources)

    params.require(:application_setting).permit(
      :default_projects_limit,
      :default_branch_protection,
      :signup_enabled,
      :signin_enabled,
      :require_two_factor_authentication,
      :two_factor_grace_period,
      :gravatar_enabled,
      :sign_in_text,
      :help_page_text,
      :home_page_url,
      :after_sign_out_path,
      :max_attachment_size,
      :session_expire_delay,
      :default_project_visibility,
      :default_snippet_visibility,
      :default_group_visibility,
      :restricted_signup_domains_raw,
      :version_check_enabled,
      :admin_notification_email,
      :user_oauth_applications,
      :shared_runners_enabled,
      :shared_runners_text,
      :max_artifacts_size,
      :metrics_enabled,
      :metrics_host,
      :metrics_port,
      :metrics_pool_size,
      :metrics_timeout,
      :metrics_method_call_threshold,
      :metrics_sample_interval,
      :recaptcha_enabled,
      :recaptcha_site_key,
      :recaptcha_private_key,
      :sentry_enabled,
      :sentry_dsn,
      :akismet_enabled,
      :akismet_api_key,
      :email_author_in_body,
      :repository_checks_enabled,
      :metrics_packet_size,
      :send_user_confirmation_email,
      :container_registry_token_expire_delay,
      restricted_visibility_levels: [],
      import_sources: [],
      disabled_oauth_sign_in_sources: []
    )
  end
end
