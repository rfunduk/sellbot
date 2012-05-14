module Sellbot
  module Mailer
    class SMTP
      def initialize( config )
        raise NotImplementedError.new( "SMTP not yet implemented." )
        @config = config
      end

      def mail( params )
      end
    end
  end
end
