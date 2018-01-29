Rails.application.configure do

	config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://localhost:9000'
        resource '*', 
        :headers => :any,
        :expose  => ['access-token', 'expiry', 'token-type', 'uid', 'client'], 
        :credentials => true, 
        :methods => [:get, :post, :options, :put, :delete]
      end
  end

  # # Code is not reloaded between requests
   config.cache_classes = true
   config.static_cache_control = "no-cache"
  # # Full error reports are disabled and caching is turned on
   config.consider_all_requests_local       = false
   config.action_controller.perform_caching = true

   config.eager_load = false

   config.consider_all_requests_local = true


  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  config.logger = Logger.new(STDOUT)

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )
  #config.assets.precompile += %w(bootstrap-datetimepicker.min.css event_calendar.css style.css youTubeEmbed-jquery-1.0.css bootstrapx-clickover.js event_calendar.js youTubeEmbed-jquery-1.0.js shortcut.js jquery.swfobject.1-1-1.min.js modules/exporting.js bootstrap-datetimepicker.min.js inflection.js jquery.nestedAccordion.js nicEdit.js popcorn-complete.min.js jquery.ui.touch-punch.js general.js)


  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.action_mailer.default_url_options = { :host => 'scalear-staging2.herokuapp.com/#' , :protocol => 'https'}
  config.action_mailer.asset_host = 'https://scalear-staging2.herokuapp.com'


  # ActionMailer Config
  # Setup for production - deliveries, no errors raised
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default :charset => "utf-8"


  config.action_mailer.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '587',
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

  config.frontend_host = "http://scalear-staging2.herokuapp/#/"

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
end


ENV['INFLUXDB_USER']='root'
ENV['INFLUXDB_PASSWORD']='root'
ENV['INFLUXDB_DATABASE']='staging_statistics'
ENV['INFLUXDB_HOST']='54.172.25.46'
ENV['INFLUXDB_PORT']='8086'