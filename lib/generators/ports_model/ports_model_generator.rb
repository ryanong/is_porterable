require 'rails/generators'
require 'rails/generators/migration'
class PortsModelGenerator < Rails::Generators::NamedBase
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  def manifest

    template('sub_model.rb', File.join('app/models', "#{file_name}_port.rb"))

  end
  
  protected
  # Override with your own usage banner.
  def banner
    "Usage: #{$0} ports"
  end
end
