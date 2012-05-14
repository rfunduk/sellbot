require 'forwardable'

# require adapters
path = File.expand_path('processors/*', File.dirname(__FILE__))
Dir.glob(path).each do |adapter|
  require adapter
end

module Sellbot
  class Payment
    extend Forwardable

    DELEGATE = %w{
      form_values confirm_order is_complete?
    }.map(&:to_sym).freeze
    delegate DELEGATE => :@instance

    attr_accessor :config
    attr_accessor :name

    def initialize
      @name = Sellbot::Config.payment[:processor]
      @processor = Sellbot::Processor.const_get @name
      @config = ::OpenStruct.new(Sellbot::Config.payment[:config]||{})
      @instance = @processor.new( @config )
    end
  end
end
