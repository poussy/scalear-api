#Rack::Timeout.timeout = 31
Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout, service_timeout: 31