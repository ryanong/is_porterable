require 'rails/generators'
require 'rails/generators/migration'
class PortsGenerator < Rails::Generators::NamedBase
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  def manifest
    # Controller templates
    %w(ports import scan).each do |action|
      template "#{action}.rhtml", File.join('app', 'views', 'shared', "#{action}.html.erb")
    end

    template('model.rb', File.join('app/models', "port.rb"))
    template('sub_model.rb', File.join('app/models', "#{file_name}_port.rb"))

    migration_template('migration.rb', 'db/migrate/create_ports.rb')
  end
  
  def self.next_migration_number(dirname)
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end
  
  protected
  # Override with your own usage banner.
  def banner
    "Usage: #{$0} ports"
  end
end