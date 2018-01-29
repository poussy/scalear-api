desc "This task is called by the Heroku scheduler add-on"
task :update_saml_metadata => :environment do
  uri = URI.parse(ENV['SAML_IDP'])
  p "START: Getting XML"
  response = Net::HTTP.get_response(uri)
  p "DONE: Getting XML"
  meta_text = response.body
  p "START: Writing file"
  target = File.join(Rails.root, 'lib','assets', 'swamid-idp-transitive.xml')
  File.open(target, "wb") do |f|
    f.write(meta_text)
  end
  p "DONE: Writing file"
end
