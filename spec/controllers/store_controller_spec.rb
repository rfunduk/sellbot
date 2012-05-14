require 'spec_helper'

Padrino.load!

describe Sellbot::Web do
  it "should redirect '/' to Config.home" do
    get '/'
    last_response.status.should == 302
    last_response.headers['Location'].should == Sellbot::Config.home
  end

  it "should display a product info page" do
    get "/#{Sellbot::Store.products.first[:id]}"
    last_response.status.should == 200
    last_response.should render_template 'store/purchase'
  end
end
