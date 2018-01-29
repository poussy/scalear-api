Rails.application.config.middleware.insert_before(ActionDispatch::Static, Rack::Zippy::AssetServer)

Rack::Zippy.configure do |config|
  config.static_extensions.delete('html')
end