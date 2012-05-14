require 'spec_helper'

describe Sellbot::Config do
  it "should have an application path" do
    Sellbot::Config.path.should_not be_nil
  end

  it "should reload its config" do
    original_title = Sellbot::Config.title
    use_config :b do
      Sellbot::Config.title.should_not eq original_title
    end
  end
end
