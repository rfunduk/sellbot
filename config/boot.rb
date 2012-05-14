# Defines our constants
PADRINO_ENV = ENV["PADRINO_ENV"] ||= ENV["RACK_ENV"] ||= "development" unless defined?(PADRINO_ENV)
PADRINO_ROOT = File.expand_path('../..', __FILE__) unless defined?(PADRINO_ROOT)

# Load our dependencies
require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, PADRINO_ENV)

Padrino::Logger::Config[:development][:stream] = :to_file

require File.join( PADRINO_ROOT, 'lib', 'core_ext' )
require File.join( PADRINO_ROOT, 'lib', 'config' )
require File.join( PADRINO_ROOT, 'lib', 'db' )
require File.join( PADRINO_ROOT, 'lib', 'store' )

Sellbot::Config.setup! path:Padrino.mounted_root, env:Padrino.env
Sellbot::Store.setup!
Sellbot::DB.new.store_version = Sellbot::Store.version

Padrino.load!
