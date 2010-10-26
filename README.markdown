is_porterable
============

Importing and Exporting is a vital feature for data administration and migration. this plugin tries to make it as easy as possible to import and export data across multiple associated tables. By adding a few lines to the model, controller, routes, and a few views. 


Example Usage
=======

First execute this code `rails generate ports `

in model/address.rb
    class Address < ActiveRecord::Base
      is_porterable
    end
in controller/address_controller.rb
    class AddressController < ApplicationController
	  include Porterable::Controller
	end
in routes
Installation
=======

This plugin is only compatible with rails 3 at the moment.
To install plugin either use gem

### Install as gem
Add the "is_porterable" gem to your Gemfile.

    gem "is_porterable"

### Install as plugin using git

    rails plugin install git@github.com:ryanong/is_porterable.git



Copyright (c) 2010 Aaron Quint, released under the MIT license
