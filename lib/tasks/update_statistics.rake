desc "This task is called by the Heroku scheduler add-on"
task :update_statistics => :environment do
	kpi = KpisController.new
	kpi.init_tempodb
	kpi.kpi_job
end
