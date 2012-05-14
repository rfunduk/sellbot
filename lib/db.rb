require 'forwardable'

# require adapters
path = File.expand_path('adapters/*', File.dirname(__FILE__))
Dir.glob(path).each do |adapter|
  require adapter
end

module Sellbot
  class DB
    extend Forwardable

    class NotFound < StandardError; end

    DELEGATE = %w{
      fetch all drop!
      store_version store_version=
      all_in_daterange all_for_item_id
      create update count
    }.map(&:to_sym).freeze
    delegate DELEGATE => :@db

    def initialize
      @adapter = Sellbot::Adapter.const_get Sellbot::Config.db[:adapter]
      @config = ::OpenStruct.new(Sellbot::Config.db[:config]||{})
      @db = @adapter.new( @config )
    end
  end
end
