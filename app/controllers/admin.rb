Sellbot::Web.controller :admin do
  layout :admin

  before except:[ :login_form, :login_action ] do
    logger.info "PARAMS: #{params.inspect}"

    # ensure we're logged in as an admin
    if !Sellbot::Config.admin.keys.include?( session[:admin_user].to_sym )
      redirect url(:admin, :login_form)
      return
    end

    @db = Sellbot::DB.new
    Sellbot::Store.ensure_newest!(@db)
  end

  get :root, map:'/admin' do
    @index = true
    render 'admin/index'
  end

  get :login_form, map:'/admin/login' do
    @index = true
    render 'admin/login'
  end
  post :login_action, map:'/admin/login' do
    # look up admin user in config
    exists = Sellbot::Config.admin[params[:login].to_sym]
    if exists && exists == params[:password]
      session[:admin_user] = params[:login]
      redirect url(:admin, :root)
    else
      flash[:error] = "Nope."
      redirect url(:admin, :login_form)
    end
  end

  get :store, map:'/admin/store' do
    @storage = Sellbot::Storage.new
    render 'admin/store'
  end
  get :reload_store, map:'/admin/reload_store' do
    Sellbot::Store.reload!
    redirect url(:admin, :store)
  end

  get :order_details, map:'/admin/order_details' do
    if params[:id]
      @orders = [@db.fetch( params[:id] )] rescue []
      partial 'admin/orders_table'
    elsif params[:start] and params[:end]
      @orders = @db.all_in_daterange( params[:start].to_i,
                                      params[:end].to_i )
      partial 'admin/orders_table'
    end
  end
  get :orders, map:'/admin/orders' do
    @count = @db.count
    render 'admin/orders'
  end
end
