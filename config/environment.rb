# Load the Rails application.
require_relative 'application'

# load env variables for development
# app_environment_variables = File.join(Rails.root, 'config', 'app_environment_variables.rb')
# load(app_environment_variables) if File.exists?(app_environment_variables)

# load env variables for development
env_file = File.join(Rails.root, 'config', 'local_env.yml')
YAML.load(File.open(env_file)).each do |key, value|
    ENV[key.to_s] = value
end if File.exists?(env_file)
 

# Initialize the Rails application.
Rails.application.initialize!
