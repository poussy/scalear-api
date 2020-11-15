Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # # Code is not reloaded between requests
  config.cache_classes = true
  # # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store
  # config.public_file_server.headers = {
  #   'Cache-Control' => "public, max-age=#{1.year.seconds.to_i}"
  # }

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  config.eager_load = false

  # See everything in the log (default is :info)
  # config.log_level = :debug

  config.logger = Logger.new(STDOUT)

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.action_mailer.default_url_options = { :host => 'test.scalable-learning.com' , :protocol => 'https'}
  config.action_mailer.asset_host = 'https://test.scalable-learning.com'

  # ActionMailer Config
  # Setup for production - deliveries, no errors raised
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default :charset => "utf-8"


  config.action_mailer.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '465',
  :authentication => :plain,
  :user_name      => ENV['SENDGRID_USERNAME'],
  :password       => ENV['SENDGRID_PASSWORD'],
  :domain         => 'heroku.com',
  :enable_starttls_auto => true
 }

  config.saml={
    :keys => {
      :private => ENV['RSA_PRIVATE'],
      :public => ENV['RSA_PUBLIC']
    },
    :idp_metadata => ENV['SAML_IDP']
  }

  config.active_record.migration_error = :page_load

  config.frontend_host = "http://test.scalable-learning.com/#/"

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
  ActiveSupport::Deprecation.silenced = true
  Rack::Timeout::Logger.disable
  config.active_record.logger = nil
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.custom_options = lambda do |event|
    params = event.payload[:params].reject do |k|
      ['controller', 'action', 'locale'].include? k
    end
    opts={}
    if !event.payload[:params]["id"].nil?
      opts[event.payload[:params]["controller"].singularize+'_id' ] = event.payload[:params]["id"]
      params.delete("id")
    end
    opts[:params] = params
    opts[:user_id] = event.payload[:user_id]
    opts[:ip] = event.payload[:ip]
    if event.payload[:exception]
      opts[:stacktrace] = %Q('#{Array(event.payload[:stacktrace]).to_json}')
    end
    opts
  end
  module Kernel; def puts(*args) end end
end

ENV['INFLUXDB_USER']='root'
ENV['INFLUXDB_PASSWORD']='root'
ENV['INFLUXDB_DATABASE']='staging_statistics'
ENV['INFLUXDB_HOST']='54.172.25.46'
ENV['INFLUXDB_PORT']='8086'
