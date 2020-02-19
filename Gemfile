source 'https://rubygems.org'
ruby '2.4.4'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :test do
	gem 'simplecov', require: false
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'devise_token_auth', '~> 0.1.42'
gem 'rack-cors', ' ~> 1.0.1'
gem 'cancancan', '~> 2.0'
gem 'validates_timeliness', '~> 4.0' 
gem 'delayed_job_active_record'
gem 'rubyzip', '>= 1.0.0' # will load new rubyzip version
gem 'zip-zip' # will load compatibility for old rubyzip API.
gem 'settingslogic'
gem 'activeresource'
gem 'aescrypt'
gem 'ruby-saml', :git => "git://github.com/karimAlaa/ruby-saml.git"
gem 'ims-lti', '~>2.2.3'
gem 'roboto'
gem 'newrelic_rpm'
gem 'influxdb'
gem "lograge"
gem "logstash-event"
gem "rack-timeout"
gem "rack-block"
gem "oink"
gem 'memory_profiler'
gem 'vimeo_me2', :git => "https://github.com/bo-oz/vimeo_me2.git"
gem "retries"
gem 'scout_apm'
gem 'canvas_cc'
gem 'streamio-ffmpeg', '1.0.0'
gem 'youtube-dl.rb'
gem 'terrapin', '~> 0.6.0' 
