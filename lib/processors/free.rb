module Sellbot
  module Processor
    class Free
      def initialize( config )
        @config = config
      end

      def form_values( order, return_url )
        {}
      end

      def confirm_order( order, params )
        { response: nil, errors: [], ok: true }
      end

      def is_complete?( p={} )
        true
      end
    end
  end
end
