module Sellbot
  module Processor
    class Stripe
      def initialize( config )
        @config = config
        @config.publishable ||= ENV['STRIPE_PUBLISHABLE']
        @config.secret ||= ENV['STRIPE_SECRET']
        ::Stripe.api_key = @config.secret
      end

      def confirm_order( order, transaction_id )
        result = { response: nil, errors: [] }
        begin
          charge = ::Stripe::Charge.create(
            :amount => order[:item][:price] * 100,
            :currency => 'usd',
            :card => transaction_id,
            :description => order[:id]
          )
          result[:response] = charge
          result[:errors] << "Transaction not successful." unless result[:response][:paid]
        rescue => e
          result[:errors] << "Transaction failed: #{e.message}"
        end

        result[:ok] = result[:errors].empty?
        return result
      end

      def is_complete?( p={} )
        true
      end
    end
  end
end
