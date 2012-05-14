module Sellbot
  module Adapter
    class DynamoDB
      def initialize( config={} )
        raise "This is an experimental adapter and doesn't really work well :("
        @db = AWS::DynamoDB.new( {
          access_key_id: ENV['AWS_ACCESS_KEY_ID'] || config.access_key_id,
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'] || config.secret_access_key
        } )
        @config = config
        create_table!
      end

      def create_table!
        @table = @db.tables[@config[:table]] ||
                 @db.tables.create( @config[:table],
                                    @config[:read],
                                    @config[:write] )
        @table.hash_key = [ :id, :string ]
        sleep 0.05 while @table.status != :active
      end

      def drop!
        @table.delete
        create_table!
      end

      def store_version
        ""
      end
      def store_version=(v)
        ""
      end

      def fetch( key )
        h = get_item(key).attributes.to_h
        h['downloads'] = JSON.parse(h['downloads']) rescue {}
        h['paypal'] = JSON.parse(h['paypal']) rescue {}
        h.recursively_symbolize_keys
      end

      def all
        @table.items
      end

      def all_for_item_id( item_id )
        @table.items.where( 'item_id' ).equals( item_id.to_s )
      end

      def all_in_daterange( s, e )
        r = @table.items.all
          .where( 'timestamp' )
          .between( start_date, end_date )
          .to_a.map { |o| clean_attributes(o.attributes.to_h) }
        r.recursively_symbolize_keys
      end

      def create( attributes )
        attributes = { id: SecureRandom.uuid }.merge( attributes )
        item = @table.items.create( attributes )
        h = clean_attributes(item.attributes.to_h)
        h.recursively_symbolize_keys
      end

      def update( order, attributes )
        key = order[:id]
        get_item(key).attributes.set( attributes )
        order.merge! attributes
      end

      def count
        @table.items.count
      end

      private

      def clean_attributes(dirty_h)
        case dirty_h
        when Set
          dirty_h.to_a.map { |v| clean_attributes( v ) }
        when Hash
          dirty_h.entries.each do |k, v|
            dirty_h[k] = clean_attributes( v )
          end
          dirty_h
        else
          dirty_h
        end
      end

      def get_item( key )
        item = @table.items.at( key )
        raise Sellbot::DB::NotFound unless item.exists?
        item
      end
    end
  end
end
