require 'forwardable'

# require adapters
path = File.expand_path('providers/*', File.dirname(__FILE__))
Dir.glob(path).each do |adapter|
  require adapter
end

module Sellbot
  class Storage
    extend Forwardable

    class NotFound < StandardError; end

    DELEGATE = %w{
      url_for
    }.map(&:to_sym).freeze
    delegate DELEGATE => :@storage

    def initialize
      @provider = Sellbot::Provider.const_get Sellbot::Config.storage[:provider]
      @config = ::OpenStruct.new(Sellbot::Config.storage[:config]||{})
      @storage = @provider.new( @config )
    end
  end
end
