require File.dirname(__FILE__) + '/../lib/caches'

require 'rubygems'
gem 'activesupport'
require 'active_support'

context "CachedClassMethod class" do
  class CachedClassMethod
    def self.test
      Time.now
    end
    extend Caches
    class_caches :test
  end
  
  Global_cached_class = %{class GlobalCachedClassMethod
    def self.test
      Time.now
    end
    extend Caches
    class_cache_storage CachesStorage::Global
    class_caches :test
  end}
  
  eval Global_cached_class
  
  specify "should cache class methods" do
    oldtime = CachedClassMethod.test
    Time.stub!(:now).and_return oldtime+10
    CachedClassMethod.test.should == oldtime
    reset_time_now
  end
  
  specify "should not cache class methods more than once (imitating Rails development mode class reloading)" do
    oldtime = GlobalCachedClassMethod.test
    Time.stub!(:now).and_return oldtime+10
    Class.remove_class GlobalCachedClassMethod
    eval Global_cached_class
    GlobalCachedClassMethod.test.should == oldtime
    reset_time_now
  end

  private

  def reset_time_now
    Time.stub!(:now).and_return { @time_now.call }
  end
  
end

context "CachedClass instance" do

  class CachedBase ; end ; CachedBase.extend Caches

  class CachedClass < CachedBase

    attr_reader :accessor_counter

    def initialize
      @accessor = "Value"
      @accessor_counter = 0
    end

    def accessor
      @accessor_counter += 1
      @accessor
    end

    def accessor=(new_val)
      @accessor = new_val
    end

    alias :accessor2 :accessor

    caches :accessor
    caches :accessor2, :timeout => 120

    def method_with_args(a,b)
      "#{a}#{b}#{Time.now}"
    end

    caches :method_with_args

  end

  setup do
    @cached = CachedClass.new
    @time_now = Time.method :now
  end


  specify "should remember values for a default interval" do
    val = @cached.accessor
    @cached.accessor_counter.should == 1
    now = Time.now
    Time.stub!(:now).and_return now
    10.times { @cached.accessor }
    @cached.accessor_counter.should == 1
    # In 60 seconds, we still cache
    Time.stub!(:now).and_return now + 60
    val = @cached.accessor
    @cached.accessor_counter.should == 1
    # In 61, cache is invalidated
    Time.stub!(:now).and_return now + 61
    val = @cached.accessor
    @cached.accessor_counter.should == 2
  end


  specify "should remember values for a non-default interval" do
    val = @cached.accessor2
    @cached.accessor_counter.should == 1
    now = Time.now
    Time.stub!(:now).and_return now    
    10.times { @cached.accessor2 }
    @cached.accessor_counter.should == 1
    # In 2 minutes, we still cache
    Time.stub!(:now).and_return now + 120
    val = @cached.accessor2
    @cached.accessor_counter.should == 1
    # In 2m1sec, cache is invalidated
    Time.stub!(:now).and_return now + 121
    val = @cached.accessor2
    @cached.accessor_counter.should == 2
  end

  specify "should invalidate cached value if new value is assigned" do
    val = @cached.accessor
    @cached.accessor_counter.should == 1

    @cached.accessor = "Hello"
    val = @cached.accessor
    @cached.accessor_counter.should == 2
  end

  specify "should invalidate cached value if asked explicitely" do
    val = @cached.accessor
    @cached.accessor_counter.should == 1

    @cached.invalidate_accessor_cache
    val = @cached.accessor
    @cached.accessor_counter.should == 2

    @cached.invalidate_all_accessor_caches
    val = @cached.accessor
    @cached.accessor_counter.should == 3

    @cached.invalidate_all_caches
    val = @cached.accessor
    @cached.accessor_counter.should == 4
  end 

  specify "should cache methods with arguments" do
    val = @cached.method_with_args("a","b")
    valA = @cached.method_with_args("a","C")
    val.should_not == valA
    OldTime = Time
    now = Time.now
    Time.stub!(:now).and_return now + 1    
    val1 = @cached.method_with_args("a","b")
    reset_time_now
    val.should == val1    
  end


  specify "should invalidate cache for method with arguments if asked explicitely" do
    # Invalidating with another arguments does not work:
    val = @cached.method_with_args("a","b")
    @cached.invalidate_method_with_args_cache("A","B")
    now = Time.now
    Time.stub!(:now).and_return now + 1    
    val1 = @cached.method_with_args("a","b")
    reset_time_now
    val.should == val1

    @cached.invalidate_all_caches
    val = @cached.method_with_args("a","b")
    @cached.invalidate_method_with_args_cache("a","b")
    now = Time.now
    Time.stub!(:now).and_return now + 1
    val1 = @cached.method_with_args("a","b")
    reset_time_now
    val.should_not == val1

    @cached.invalidate_all_caches

    val = @cached.method_with_args("a","b")
    @cached.invalidate_all_method_with_args_caches
    now = Time.now
    Time.stub!(:now).and_return now + 1    
    val1 = @cached.method_with_args("a","b")
    reset_time_now
    val.should_not == val1

    @cached.invalidate_all_caches

    val = @cached.method_with_args("a","b")
    @cached.invalidate_all_caches
    now = Time.now
    Time.stub!(:now).and_return now + 1    
    val1 = @cached.method_with_args("a","b")
    reset_time_now
    val.should_not == val1
  end 

  specify "invalidate all caches except specified" do
    val = @cached.accessor
    val2 = @cached.accessor2
    valM = @cached.method_with_args("a","b")
    @cached.invalidate_all_caches :except => :method_with_args
    now = Time.now
    Time.stub!(:now).and_return now + 1    
    valM1 = @cached.method_with_args("a","b")
    reset_time_now
    valM.should == valM1

    @cached.invalidate_all_caches

    val = @cached.accessor
    val2 = @cached.accessor2
    valM = @cached.method_with_args("a","b")
    @cached.invalidate_all_caches :except => [:method_with_args]
    now = Time.now
    Time.stub!(:now).and_return now + 1    
    valM1 = @cached.method_with_args("a","b")
    reset_time_now
    valM.should == valM1
  end



  private

  def reset_time_now
    Time.stub!(:now).and_return { @time_now.call }
  end


end