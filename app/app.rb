class Sellbot::Web < Padrino::Application
  register Padrino::Rendering
  register Padrino::Mailer
  register Padrino::Helpers

  enable :sessions
  disable :reload if Padrino.env == :production

  register Padrino::Cache
  enable :caching

  set :cache, Padrino::Cache::Store::Memory.new(50)
  #set :cache, Padrino::Cache::Store::File.new(Padrino.root('tmp', app_name.to_s, 'cache')) # default choice

  configure :development do; end
  configure :production do; end

  helpers do
    def confirm_order( transaction_id )
      payment = Sellbot::Payment.new
      status = payment.confirm_order( @order, transaction_id )
      begin
        @db.update(
          @order, {
            verified: status[:ok],
            ext: status
          }
        )
      rescue
        logger.debug "Order update ERROR: #{$!.inspect}"
      end
    end
  end

  error 404 do
    render 'errors/404'
  end

  error 505 do
    render 'errors/505'
  end
end
