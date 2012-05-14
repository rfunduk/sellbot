module Sellbot
  module Mailer
    class SES
      def initialize( config )
        raise NotImplementedError.new( "AWS SES not yet implemented." )
        @config = config
        @ses = AWS::SimpleEmailService.new( {
          access_key_id: ENV['AWS_ACCESS_KEY_ID'] || config.access_key_id,
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'] || config.secret_access_key
        } )
      end

      def mail( params )
        @ses.send_email(
          :subject => params[:subject],
          :from => @config[:from],
          :to => 'receipient@domain.com',
          :body_text => 'Sample email text.',
          :body_html => '<h1>Sample Email</h1>'
        )
      end
    end
  end
end
