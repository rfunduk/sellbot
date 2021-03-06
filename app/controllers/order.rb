Sellbot::Web.controller :order do
  before do
    @db = Sellbot::DB.new
    @storage = Sellbot::Storage.new
  end

  post :check, map:'/check/:uuid' do
    @order = @db.fetch( params[:uuid] )
    if params[:tx].blank?
      # if we don't have a transaction id we have
      # to wait for the ipn
      @try_again = params[:attempts_left].to_i > 0
      sleep 3
    else
      confirm_order(params[:tx]) unless @order[:verified]
    end

    #logger.debug "UPDATED ORDER: #{@order.inspect}"
    if @order[:verified]
      @items = Sellbot::Store.find_items( @order[:item][:id] )
      partial 'store/success'
    else
      partial 'store/fail'
    end
  end

  post :complete, map:'/ipn/:uuid' do
    @order = @db.fetch( params[:uuid] )
    confirm_order( params[:txn_id] ) unless @order[:verified]
    halt 200, ''
  end

  get :complete, map:'/complete/:uuid' do
    @order = @db.fetch( params[:uuid] )
    if @order[:verified]
      redirect url(:order, :show, uuid:@order[:id])
    else
      payment = Sellbot::Payment.new
      @completed = payment.is_complete?( params )
      render 'store/complete'
    end
  end

  get :denied, map:'/denied/:uuid' do
    render 'order/denied'
  end

  get :download, map:'/download/:uuid/:item_id/:file_key' do
    @order = @db.fetch( params[:uuid] )
    @item = @order[:item]
    if @item[:kind] == :package
      @item = @item[:contents].find { |i| i[:id] == params[:item_id] }
    end

    if @order[:verified] && !@item.nil?
      count_key = "#{@item[:id]}/#{params[:file_key]}".to_sym

      max_downloads = (Sellbot::Config.max_downloads || (1/0.0))
      future_count = (@order[:downloads][count_key] || 0) + 1
      if future_count > max_downloads
        redirect url(:order, :denied, uuid:@order[:id])
      else
        @db.update(
          @order,
          downloads: @order[:downloads].merge( {
            count_key => future_count
          } ).to_json
        )
        redirect @storage.url_for( @item[:files][params[:file_key].to_sym] )
      end
    else
      halt 404, "Not found"
    end
  end

  get :show, map:'/order/:uuid' do
    @order = @db.fetch params[:uuid]
    if @order[:verified]
      @items = @order[:item][:kind] == :package ?
        @order[:item][:contents] :
        [@order[:item]]
      #logger.debug "Found items #{@items.inspect}"
      render 'order/show'
    else
      render 'order/incomplete'
    end
  end
end
