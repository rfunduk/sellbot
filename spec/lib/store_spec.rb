require 'spec_helper'

describe Sellbot::Store do
  it "should have a version" do
    Sellbot::Store.version.should_not be_empty
  end

  it "should update the store when verifying version" do
    db = Sellbot::DB.new
    db.drop!
    original_version = Sellbot::Store.version
    use_store :large, skip_reload:true do
      Sellbot::Store.version.should == original_version
      Sellbot::Store.ensure_newest! db
      Sellbot::Store.version.should_not == original_version
    end
  end

  it "should have packages and products" do
    use_store :small
    Sellbot::Store.packages.should be_an Array
    Sellbot::Store.products.should be_an Array
  end

  it "should find purchaseable products" do
    product = Sellbot::Store.products.first
    found = Sellbot::Store.find_purchaseable product[:id]
    found.should == product
  end

  it "should find purchaseable packages" do
    package = Sellbot::Store.packages.first
    found = Sellbot::Store.find_purchaseable package[:id]
    found.should == package
  end

  it "should find product items" do
    product = Sellbot::Store.products.first
    found = Sellbot::Store.find_items product[:id]
    found.should == [product]
  end

  it "should find package items" do
    package = Sellbot::Store.packages.first
    found = Sellbot::Store.find_items package[:id]
    found.should == package[:contents]
  end

  it "should reload its configuration" do
    use_store :small
    current_products = Sellbot::Store.products

    use_store :large
    Sellbot::Store.products.length.should be > current_products.length
  end

  it "should raise with no products" do
    -> { use_store :noproducts }.should raise_error(
      Sellbot::Store::InvalidConfiguration
    )
  end

  it "should not raise with no packages" do
    -> { use_store :nopackages }.should_not raise_error
  end

  it "should raise with an invalid package" do
    -> { use_store :invalidpackage }.should raise_error(
      Sellbot::Store::InvalidConfiguration
    )
  end
end
