module Sellbot
  module Mailer
    class Postmark
      def initialize( config )
        raise NotImplementedError.new( "Postmark not yet implemented." )
        @config = config
      end

      def mail( params )
      end
    end
  end
end
