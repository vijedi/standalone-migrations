APP_BASE = File.dirname(File.expand_path(__FILE__))

# Add to load_path every "lib/" directory
Dir["#{APP_BASE}/**/lib"].each { |p| $: << p }

namespace :db do
  def get_config 
    return YAML.load_file(APP_BASE + '/config/database.yml')[ENV['RAILS_ENV']]
  end
  
  task :ar_init do
    require 'active_record'
    ENV['RAILS_ENV'] ||= 'development'
    config = get_config
    ActiveRecord::Base.establish_connection(config)
    logger = Logger.new $stderr
    logger.level = Logger::INFO
    ActiveRecord::Base.logger = logger
  end

  desc "Migrate the database using the scripts in the migrate directory. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
  task :migrate => :ar_init  do
    require 'migration_helpers/init'
    require 'redhillonrails_core/init'
    require 'foreign_key_migrations/init'

    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveRecord::Migrator.migrate(APP_BASE + "/migrations/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task[ "db:schema:dump" ].execute
  end

  namespace :schema do
    desc "Create schema.rb file that can be portably used against any DB supported by AR"
    task :dump => :ar_init do
      require 'active_record/schema_dumper'
      File.open(ENV['SCHEMA'] || APP_BASE + "/schema.rb", "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end

    desc "Load a ar_schema.rb file into the database"
    task :load => :ar_init do
      file = ENV['SCHEMA'] || APP_BASE + "/schema.rb"
      load(file)
    end
  end

  desc "Create a new migration"
  task :new_migration do |t|
    unless ENV['name']
      puts "Error: must provide name of migration to generate."
      puts "For example: rake #{t.name} name=add_field_to_form"
      exit 1
    end

    underscore = lambda { |camel_cased_word|
      camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    }

    migration  = underscore.call( ENV['name'] )
    file_name  = "migrations/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_#{migration}.rb"
    class_name = migration.split('_').map { |s| s.capitalize }.join

    file_contents = <<eof
class #{class_name} < ActiveRecord::Migration
  def self.up
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
eof
    File.open(file_name, 'w') { |f| f.write file_contents }

    puts "Created migration #{file_name}"
  end

  desc 'Create the database defined in config/database.yml for the current RAILS_ENV'
  task :create => :ar_init do
    create_database(get_config)
  end

  def create_database(config)
    begin
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection
    rescue
      case config['adapter']
      when 'mysql'
        @charset   = ENV['CHARSET']   || 'utf8'
        @collation = ENV['COLLATION'] || 'utf8_general_ci'
        begin
          ActiveRecord::Base.establish_connection(config.merge('database' => nil))
          ActiveRecord::Base.connection.create_database(config['database'], :charset => (config['charset'] || @charset), :collation => (config['collation'] || @collation))
          ActiveRecord::Base.establish_connection(config)
        rescue
          $stderr.puts "Couldn't create database for #{config.inspect}, charset: #{config['charset'] || @charset}, collation: #{config['collation'] || @collation} (if you set the charset manually, make sure you have a matching collation)"
        end
      when 'postgresql'
        @encoding = config[:encoding] || ENV['CHARSET'] || 'utf8'
        begin
          ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
          ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => @encoding))
          ActiveRecord::Base.establish_connection(config)
        rescue
          $stderr.puts $!, *($!.backtrace)
          $stderr.puts "Couldn't create database for #{config.inspect}"
        end
      when 'sqlite'
        `sqlite "#{config['database']}"`
      when 'sqlite3'
        `sqlite3 "#{config['database']}"`
      end
    else
      $stderr.puts "#{config['database']} already exists"
    end
  end

  namespace :drop do
    desc 'Drops all the local databases defined in config/database.yml'
    task :all => :ar_init do
      ActiveRecord::Base.configurations.each_value do |config|
        # Skip entries that don't have a database key
        next unless config['database']
        # Only connect to local databases
        local_database?(config) { drop_database(config) }
      end
    end
  end

  desc 'Drops the database for the current RAILS_ENV'
  task :drop => :ar_init do
    config = get_config
    begin
      drop_database(config)
    rescue Exception => e
      puts "Couldn't drop #{config['database']} : #{e.inspect}"
    end
  end

  def local_database?(config, &block)
    if %w( 127.0.0.1 localhost ).include?(config['host']) || config['host'].blank?
      yield
    else
      puts "This task only modifies local databases. #{config['database']} is on a remote host."
    end
  end
  
end


def drop_database(config)
  case config['adapter']
  when 'mysql'
    ActiveRecord::Base.connection.drop_database config['database']
  when /^sqlite/
    FileUtils.rm(File.join(RAILS_ROOT, config['database']))
  when 'postgresql'
    ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
    ActiveRecord::Base.connection.drop_database config['database']
  end
end