module Sellbot
  module Adapter
    class Redis
      def initialize( config={} )
        uri = URI.parse( ENV['REDIS_URI'] || config.uri )
        redis = ::Redis.connect(
          url: uri.host,
          port: uri.port,
          thread_safe: true
        )
        Config.log "Redis using namespace #{config.namespace}"
        @redis = ::Redis::Namespace.new( config.namespace || 'sellbot',
                                         redis: redis )
      end

      def drop!
        # unfortunately we can't use flushall here
        # because it doesn't honor namespace
        # also, can't just do @redis.del(*keys)
        # because of an oddity in the gem, it seems...
        @redis.keys('*').each { |k| @redis.del k }
      end

      def store_version
        @redis.get 'store_version'
      end
      def store_version=(v)
        @redis.set 'store_version', v
      end

      def fetch( key )
        get_item( key )
      end

      def all
        @redis.keys("order:*").collect do |key|
          get_item(key.split(':').last, true)
        end
      end

      def all_in_daterange( s, e )
        @redis.zrangebyscore("timestamps", s, e).collect do |key|
          get_item(key, true)
        end
      end

      def all_for_item_id( item_id )
        @redis.smembers("items:#{item_id}").collect do |key|
          get_item(key, true)
        end
      end

      def create( attributes )
        # clean up some attributes
        if attributes[:item]
          # break out item key into kind & item_id
          item = attributes.delete :item
          attributes[:kind] = item[:kind].to_s
          attributes[:item_id] = item[:id].to_s
        end
        attributes[:ext] = attributes[:ext].to_json if attributes[:ext].is_a?(Hash)
        attributes[:verified] = attributes[:verified] ? 1 : 0
        attributes[:timestamp] = attributes[:timestamp].to_i

        attributes = { id: SecureRandom.uuid }.merge( attributes )
        @redis.hmset "order:#{attributes[:id]}", *attributes.to_a.flatten

        # push into set by item, for lookup in admin
        @redis.sadd "items:#{attributes[:item_id]}", attributes[:id]

        # push into a sorted date set, for lookup in admin
        @redis.zadd "timestamps", attributes[:timestamp], attributes[:id]

        get_item( attributes[:id], true )
      end

      def update( order, attributes )
        key = order[:id]
        h = get_item(key)
        order.merge! create( h.merge( attributes ) )
      end

      def count
        @redis.keys("order:*").size
      end

      private

      def get_item( key, sure_to_exist=false )
        id = "order:#{key}"
        raise Sellbot::DB::NotFound unless sure_to_exist || @redis.exists( id )
        h = @redis.hgetall id
        h['verified'] = h['verified'].to_i == 1
        h['item'] = Sellbot::Store.find_purchaseable h.delete('item_id')
        h['downloads'] = JSON.parse(h['downloads']) rescue {}
        h['ext'] = JSON.parse(h['ext']) rescue {}
        h['timestamp'] = h['timestamp'].to_i
        h.recursively_symbolize_keys
      end
    end
  end
end
