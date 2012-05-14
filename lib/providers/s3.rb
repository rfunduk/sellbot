module Sellbot
  module Provider
    class S3
      def initialize( config )
        @s3 = AWS::S3.new( {
          access_key_id: ENV['AWS_ACCESS_KEY_ID'] || config.access_key_id,
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'] || config.secret_access_key
        } )
        @bucket = @s3.buckets[config.bucket]
      end

      def url_for( item, opts={} )
        @bucket.objects[item].url_for(
          :read,
          {
            :expires => (60 * 5),
            :secure => false
          }.merge(opts)
        ).to_s # NO URI!
      end
    end
  end
end
