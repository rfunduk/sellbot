require 'forwardable'

# require adapters
path = File.expand_path('mailers/*', File.dirname(__FILE__))
Dir.glob(path).each do |adapter|
  require adapter
end

module Sellbot
  class Mail
    extend Forwardable

    DELEGATE = %w{}.map(&:to_sym).freeze
    delegate DELEGATE => :@instance

    def initialize
      @mailer = Sellbot::Mailer.const_get Sellbot::Config.mail[:mailer]
      @config = ::OpenStruct.new(Sellbot::Config.mail[:config]||{})
      @instance = @mailer.new( @config )
    end

    def mail( params )
      params[:subject] = subject_from params
      @instance.mail params
    end

    private

    SUB_SCANNER = /\{\{([^}\s]+?)\}\}/

    def subject_from( params )
      # construct subject
      order = params[:order]
      subject = @config[:purchase_subject]
      subject.dup.scan( SUB_SCANNER ).each do |to_sub|
        subject.sub!( "{{#{to_sub}}}", order[to_sub.to_sym] )
      end
      subject
    end
  end
end
