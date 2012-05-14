module Sellbot
  module Processor
    class Braintree
      def initialize( config )
        raise NotImplementedError.new( "Braintree payment processor not yet implemented." )
      end
    end
  end
end
