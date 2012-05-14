module Sellbot
  module Adapter
    class Sequel
      def initialize( config={} )
        raise NotImplementedError.new( "Sequel adapter not yet implemented." )
      end
    end
  end
end
