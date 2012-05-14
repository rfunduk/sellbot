PADRINO_ROOT = File.expand_path File.dirname(__FILE__) + "/.."
PADRINO_LOG_LEVEL = ENV['LOG'] ? 'development' : 'test'
PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)

require "#{PADRINO_ROOT}/lib/core_ext"
require "#{PADRINO_ROOT}/lib/config"
require "#{PADRINO_ROOT}/lib/store"
require "#{PADRINO_ROOT}/lib/db"

require 'rubygems' unless defined? Gem
require 'bundler/setup'
Bundler.require :default, 'test'

def using_constants( klass, new_constants )
  klass = klass.call if klass.is_a? Proc
  klass = klass.class unless klass.is_a? Class
  old_constants = {}
  begin
    new_constants.each_pair do |name, value|
      old_constants[name] = klass.__send__( :remove_const, name )
      klass.const_set( name, value )
    end

    yield
  ensure
    old_constants.each_pair do |name, value|
      klass.__send__( :remove_const, name )
      klass.const_set( name, value )
    end
  end
end

def app
  Sellbot::Web.tap { |app|  }
end

def use_store( name, opts={}, &block )
  using_constants Sellbot::Store, LOAD_PATH: "spec/support/store-#{name}.yml" do
    Sellbot::Store.reload! unless opts[:skip_reload]
    yield if block_given?
  end
end

def use_config( name, opts={}, &block )
  using_constants Sellbot::Config, LOAD_PATH: "spec/support/config-#{name}.yml" do
    Sellbot::Config.reload! unless opts[:skip_reload]
    return yield if block_given?
  end
end

RSpec.configure do |conf|
  conf.before( :each ) do
    use_config( :a )
    use_store( :small )
  end

  conf.include Rack::Test::Methods
end

use_config :a, skip_reload:true do
  Sellbot::Config.setup! path:PADRINO_ROOT, env:PADRINO_ENV
end
use_store :small, skip_reload:true do
  Sellbot::Store.setup!
end

Sellbot::DB.new.store_version = Sellbot::Store.version
