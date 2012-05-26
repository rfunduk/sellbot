Sellbot::Web.controller :store do
  before do
    logger.info "PARAMS: #{params.inspect}"
    @db = Sellbot::DB.new
    #@mailer = Sellbot::Mail.new
    Sellbot::Store.ensure_newest!(@db)
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
          :order,
          :complete,
          :uuid => @order[:id]
        )

        @notify_url = Sellbot::Config.host + url_for(
          :order,
          :complete,
          :uuid => @order[:id]
        )

        @payment = Sellbot::Payment.new
        processor = Sellbot::Config.payment[:processor].downcase
        partial "store/payment_processors/#{processor}"
      else
        halt 404, "Not Found"
      end
    end
  end

  get :start, map:'/:id' do
    begin
      @item = Sellbot::Store.find_purchaseable( params[:id] )
      render 'store/purchase'
    rescue Sellbot::Store::NotFound
      halt 404, "Not found"
    end
  end

  get :root, map:'/' do
    redirect Sellbot::Config.home
  end
end
