Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' #'http://scalear-staging.s3-website-eu-west-1.amazonaws.com'  #* #angular-edu.herokuapp.com
        resource '*', 
        :headers => :any,
        :expose  => ['access-token', 'expiry', 'token-type', 'uid', 'client'], 
        :methods => [:get, :post, :options, :put, :delete]
      end
  end

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{1.year.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { :host => 'localhost', :port => 3000 }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.asset_host = 'http://localhost:3000'
  config.action_mailer.smtp_settings = {
      address: "smtp.gmail.com",
      port: 587,
      domain: 'gmail.com',
      authentication: "plain",
      enable_starttls_auto: true,
      user_name: 'scalear.testing@gmail.com',
      password: 'carmen.white'
    }
  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load


  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.frontend_host = "http://localhost:9000/#/"

  ActiveSupport::Deprecation.silenced = true
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
ENV['INFLUXDB_DATABASE']='production_statistics'
# ENV['INFLUXDB_DATABASE']='staging_statistics'
ENV['INFLUXDB_HOST']='54.172.25.46'
ENV['INFLUXDB_PORT']='8086'
