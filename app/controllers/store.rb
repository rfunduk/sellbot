Sellbot::Web.controller :store do
  before do
    logger.info "PARAMS: #{params.inspect}"
    @db = Sellbot::DB.new
    #@mailer = Sellbot::Mail.new
    @payment = Sellbot::Payment.new
    Sellbot::Store.ensure_newest!(@db)
  end

  post :check, map:'/check/:uuid' do
    @order = @db.fetch( params[:uuid] )
    unless @order[:verified]
      status = @payment.confirm_order( @order, params )
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
    logger.debug "UPDATED ORDER: #{@order.inspect}"
    if @order[:verified]
      @items = Sellbot::Store.find_items( @order[:item][:id] )
      partial 'store/success'
    else
      partial 'store/fail'
    end
  end

  get :complete, map:'/complete/:uuid' do
    @order = @db.fetch( params[:uuid] )
    if @order[:verified]
      redirect url(:order, :show, uuid:@order[:id])
    else
      @completed = @payment.is_complete?( params )
      render 'store/complete'
    end
  end

  post :order, map:'/order' do
    if !Sellbot::Config.email_optional && params[:email].blank?
      @item_id = params[:item]
      @error = true
      partial 'store/signup'
    else
      @item = Sellbot::Store.find_purchaseable( params[:item] )

      if @item
        session[:email] = params[:email].blank? ?
          "none@given.com" :
          params[:email]

        @order = @db.create(
          email: session[:email],
          timestamp: Time.now,
          item: @item
        )

        @complete_url = Sellbot::Config.host + url_for(
          :store,
          :complete,
          :uuid => @order[:id]
        )

        processor = Sellbot::Config.payment[:processor].downcase
        partial "store/payment_processors/#{processor}"
      else
        halt 404, "Not Found"
      end
    end
  end

  get :start, map:'/:id' do
    if @item = Sellbot::Store.find_purchaseable( params[:id] )
      render 'store/purchase'
    else
      halt 404, "Not found"
    end
  end

  get :root, map:'/' do
    redirect Sellbot::Config.home
  end
end
