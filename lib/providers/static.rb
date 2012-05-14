module Sellbot
  module Provider
    class Static
      def initialize( config )
      end

      def url_for( item )
        item
      end
    end
  end
end
