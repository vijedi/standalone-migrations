module RedHillConsulting
    module ForeignKeyMigrations
    end
end

require 'red_hill_consulting/foreign_key_migrations/active_record/base'
require 'red_hill_consulting/foreign_key_migrations/active_record/migration'
require 'red_hill_consulting/foreign_key_migrations/active_record/connection_adapters/table_definition'

ActiveRecord::Base.send(:include, RedHillConsulting::ForeignKeyMigrations::ActiveRecord::Base)
ActiveRecord::Migration.send(:include, RedHillConsulting::ForeignKeyMigrations::ActiveRecord::Migration)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, RedHillConsulting::ForeignKeyMigrations::ActiveRecord::ConnectionAdapters::TableDefinition)
