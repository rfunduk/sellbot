require 'ostruct'

module Sellbot
  class Config
    LOAD_PATH = 'config/config.yml'

    DEFAULTS = {
      email_optional: false,
      max_downloads: 5,
      price: {
        unit: '$',
        precision: 0
      }
    }

    class << self
      attr_reader :path, :env

      def setup!( opts={} )
        @path = opts[:path]
        @env = (opts[:env] || 'development').to_s
        self.reload!
      end

      def reload!
        self.log "Loading config from #{LOAD_PATH}..."
        config_file = File.join( @path, LOAD_PATH )
        config = YAML::load_file( config_file )[@env]
        config = DEFAULTS.merge(config.recursively_symbolize_keys)
        config[:env] = @env.to_sym
        @@config = ::OpenStruct.new config
      end

      def log( *args )
        if defined? Padrino.logger
          Padrino.logger.info *args
        else
          $stdout.puts *args
        end
      end
    end

    def self.method_missing(method, *args)
      @@config.send( method, *args )
    end
  end
end
