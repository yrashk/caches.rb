module ActiveRecord ; class Base ; end ; end

require File.dirname(__FILE__) + '/../lib/caches'

context "ActiveRecord instance" do
  ActiveRecord::Base.extend Caches
  ActiveRecord::Base.instance_cache_storage CachesStorage::ClassVarById

  
  class Model < ActiveRecord::Base
    attr_reader :accessor_counter
    attr_accessor :id

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

  end

  setup do
    @model = Model.new
    @model.id = 1
    @model1 = Model.new
    @model1.id = 1
    @model2 = Model.new
    @model2.id = 2
  end

  specify "should remember caches across instances with the same ID" do
    @model.accessor = "hello"
    @model.accessor.should == "hello"
    @model1.accessor.should == "hello"
    @model1.accessor_counter.should == 0
  end

  specify "should not remember caches across instances with different IDs" do
    @model.accessor = "hello"
    @model.accessor.should == "hello"
    @model2.accessor.should_not == "hello"
    @model2.accessor_counter.should == 1
  end


end
