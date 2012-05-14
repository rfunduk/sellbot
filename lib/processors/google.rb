module Sellbot
  module Processor
    class Google
      def initialize( config )
        raise NotImplementedError.new( "Google payment processor not yet implemented." )
      end
    end
  end
end
