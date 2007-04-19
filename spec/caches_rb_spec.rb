require File.dirname(__FILE__) + '/../lib/caches'

require 'rubygems'
gem 'activesupport'
require 'active_support'

context "Fake class extended by Caches" do

  setup do
    @fake = Class.new
    @fake.class_eval do
      extend Caches
    end
  end

  specify "should respond to caches" do
    @fake.should respond_to(:caches)
  end

  specify "should cache for 1 minute by default" do
    cached_time_check
  end

  specify "should work with specified timeout" do
    [100,101,120].each { |timeout| cached_time_check :timeout => timeout }
  end  

  def cached_time_check(opts={})
    timeout = opts[:timeout] || 60
    @fake.class_eval do
      def test_method
        Time.now 
      end
    end
    @fake.caches(:test_method, opts)
    fake_instance = @fake.new
    old_time = fake_instance.test_method
    Time.stub!(:now).and_return old_time + timeout
    fake_instance.test_method.should == old_time
    Time.stub!(:now).and_return old_time + timeout + 1
    fake_instance.test_method.should_not == old_time 
  end

end  
