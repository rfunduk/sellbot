module Sellbot
  module Processor
    class Free
      def initialize( config )
        @config = config
      end

      def confirm_order( *args )
        { response: nil, errors: [], ok: true }
      end

      def is_complete?( p={} )
        true
      end
    end
  end
end
