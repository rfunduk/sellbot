module Sellbot
  module Processor
    class Paypal
      include Padrino::Helpers::NumberHelpers

      def initialize( config )
        @config = config
        @config.cert_id ||= ENV['PAYPAL_CERT_ID']
        @config.business_id ||= ENV['PAYPAL_BUSINESS_ID']
        @config.identity_token ||= ENV['PAYPAL_IDENTITY_TOKEN']
      end

      def form_values( order, return_url )
        values = {
          :cmd => "_cart",
          :business => @config.business_id,
          :currency_code => "CAD",
          :upload => 1,
          :return => return_url,
          :notify_url => '',
          :invoice => SecureRandom.uuid,
          :tax_cart => number_with_precision( 0, precision: 2 ),
          :cert_id => @config.cert_id
        }

        values.merge!( {
          "amount_1" => number_with_precision(
            order[:item][:price].to_f,
            precision: 2
          ),
          "item_name_1" => order[:item][:name],
          "quantity_1" => 1
        } )

        { encrypted: encrypt_for_paypal(values) }
      end

      def is_complete?( params )
        params[:st] == 'Completed'
      end

      def confirm_order( order, params )
        transaction_id = params[:tx]
        check = ::Nestful.post(
          "https://www.sandbox.paypal.com/cgi-bin/webscr",
          format: :form,
          params: {
            cmd: '_notify-synch',
            tx: transaction_id,
            at: @config.identity_token
          }
        )
        lines = check.lines.to_a

        r = {
          success: lines.shift.strip == 'SUCCESS'
        }

        result = { response: r, errors: [] }

        result[:errors] << "Transaction not successful." unless r[:success]
        return result if result[:errors].any?

        # the rest turn into k=>v
        lines.each do |line|
          k, v = line.split('=')
          r[k.to_sym] = v.strip
        end

        result[:errors] << "Payment not complete." if r[:payment_status] != 'Completed'

        result[:ok] = result[:response][:success] && result[:errors].empty?
        return result
      end

      private

      PAYPAL_CERT_PEM_FILE = "#{Config.path}/etc/certs/paypal_cert.pem"
      PAYPAL_CERT_PEM = if File.exists?(PAYPAL_CERT_PEM_FILE)
        File.read(PAYPAL_CERT_PEM_FILE)
      else
        ENV['PAYPAL_CERT']
      end

      APP_CERT_PEM_FILE = "#{Config.path}/etc/certs/app_cert.pem"
      APP_CERT_PEM = if File.exists?(APP_CERT_PEM_FILE)
        File.read(APP_CERT_PEM_FILE)
      else
        ENV['PAYPAL_APP_CERT']
      end

      APP_KEY_PEM_FILE = "#{Config.path}/etc/certs/app_key.pem"
      APP_KEY_PEM = if File.exists?(APP_KEY_PEM_FILE)
        File.read(APP_KEY_PEM_FILE)
      else
        ENV['PAYPAL_APP_KEY']
      end

      unless [PAYPAL_CERT_PEM, APP_CERT_PEM, APP_KEY_PEM].all?
        required_files = [PAYPAL_CERT_PEM_FILE, APP_CERT_PEM_FILE, APP_KEY_PEM_FILE]
        raise "#{self.name} requires certs to exist: #{required_files.join(', ')}"
      end

      def encrypt_for_paypal(values)
        # from railscasts paypal episode
        # http://railscasts.com/episodes/143-paypal-security?view=asciicast
        OpenSSL::PKCS7::encrypt(
          [OpenSSL::X509::Certificate.new(PAYPAL_CERT_PEM)],
          OpenSSL::PKCS7::sign(
            OpenSSL::X509::Certificate.new(APP_CERT_PEM),
            OpenSSL::PKey::RSA.new(APP_KEY_PEM, ''),
            values.map { |k, v| "#{k}=#{v}" }.join("\n"),
            [], OpenSSL::PKCS7::BINARY
          ).to_der,
          OpenSSL::Cipher::Cipher::new("DES3"),
          OpenSSL::PKCS7::BINARY
        ).to_s.gsub("\n", "")
      end
    end
  end
end
