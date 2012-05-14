require 'spec_helper'

SORT_BY = lambda { |field| lambda { |h| h[field.to_sym] } }
BY_ID = SORT_BY[:id]
BY_TIMESTAMP = SORT_BY[:timestamp]

describe Sellbot::DB do
  before { @db = Sellbot::DB.new; @db.drop! }

  describe "dropping the database" do
    it "should drop the database" do
      @db.create item:Sellbot::Store.products.first
      @db.count.should == 1
      @db.drop!
      @db.count.should == 0
    end

    it "should not drop _other_ databases!" do
      @db.create item:Sellbot::Store.products.first
      use_config :b do
        @db2 = Sellbot::DB.new
        @db2.drop!
        @db2.create item:Sellbot::Store.products.last
        @db.drop!
        @db.count.should == 0
        @db2.count.should == 1
      end
    end
  end

  it "should count orders when empty" do
    @db.count.should == 0
  end

  it "should keep a store version" do
    @db.store_version = Sellbot::Store.version
    @db.store_version.should == Sellbot::Store.version
  end

  describe "with a new order" do
    before :each do
      p = Sellbot::Store.products.first
      @order = @db.create( {
        email: "test@test.com",
        timestamp: Time.now,
        item: p
      } )
    end

    it "should be counted" do
      @db.count.should == 1
    end

    it "should be inserted" do
      @order.should_not be_nil
    end

    it "should updated" do
      @order[:verified].should be_false
      @db.update @order, verified:true
      @order[:verified].should_not be_nil
    end

    it "should be fetchable" do
      @order.should == @db.fetch( @order[:id] )
    end
  end

  describe "with several new orders" do
    before :each do
      ps = Sellbot::Store.products
      @orders = []
      @by_product = Hash.new { |h,k| h[k] = [] }
      5.times do |i|
        product = ps[rand(ps.length)-1]
        order = @db.create( {
          email: "test#{i}@test.com",
          timestamp: Time.now - (i*60*60),
          item: product
        } )
        @by_product[product[:id]] << order
        @orders << order
      end
    end

    it "should count all orders" do
      @db.count.should == @orders.size
    end

    it "should fetch all orders" do
      all = @db.all.sort_by( &BY_ID )
      all.should == @orders.sort_by( &BY_ID )
    end

    it "should find orders by product" do
      @by_product.keys.each do |product_id|
        orders = @db.all_for_item_id( product_id ).sort_by( &BY_ID )
        orders.should == @by_product[product_id].sort_by( &BY_ID )
      end
    end

    it "should find orders by daterange" do
      to_find = @orders.sort_by( &BY_TIMESTAMP )[2..-1]
      found = @db.all_in_daterange(
        to_find.first[:timestamp],
        to_find.last[:timestamp]
      )
      to_find.should == found.sort_by( &BY_TIMESTAMP )
    end
  end
end
