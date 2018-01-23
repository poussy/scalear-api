namespace :db do
  versions_to_skip = [
    "20171016103808",
    "20171016112531",
    "20171016130848",
    "20171016140632",
    "20171016144350",
    "20171016150206",
    "20171016160952",
    "20171016162905",
    "20171016163928",
    "20171016164453",
    "20171017085351",
    "20171022092133",
    "20171101095712",
    "20171105104403",
    "20171106080525",
    "20171106081419",
    "20171106092240",
    "20171106094710",
    "20171106094717",
    "20171106120406",
    "20171106163107",
    "20171108114546",
    "20171108122544",
    "20171108133046",
    "20171108142801",
    "20171108143324",
    "20171108144254",
    "20171108144944",
    "20171108145835",
    "20171108150701",
    "20171108151117",
    "20171108151632",
    "20171108152542",
    "20171108153633",
    "20171108154227",
    "20171108154607",
    "20171108155358",
    "20171108155921",
    "20171108160438",
  ]

  task :skip_migrations_staging2 => :environment do
    puts "Start `skip_migrations`"
    versions_to_skip.each do |version|
      puts "skipping #{version}"
      ActiveRecord::Base.connection.execute("INSERT INTO schema_migrations (version) SELECT #{version} WHERE NOT EXISTS ( SELECT version FROM schema_migrations WHERE version = '#{version}')")
    end
    puts "End `skip_migrations`"
  end

end
