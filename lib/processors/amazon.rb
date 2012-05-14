module Sellbot
  module Processor
    class Amazon
      def initialize( config )
        raise NotImplementedError.new( "Amazon payment processor not yet implemented." )
      end
    end
  end
end
