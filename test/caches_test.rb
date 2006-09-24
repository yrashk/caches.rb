require 'test/unit'  
require 'test/time_mock'

require File.dirname(__FILE__) + "/../init"                                                                                                          

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

class CachesTest < Test::Unit::TestCase

	def setup
		@cached = CachedClass.new
	end

	def teardwon
		Time.forced_now_time = nil
	end		

	def test_default_timeout
		val = @cached.accessor
		assert_equal 1, @cached.accessor_counter
		Time.forced_now_time = Time.now
		10.times { @cached.accessor }
		assert_equal 1, @cached.accessor_counter
		# In 60 seconds, we still cache
		Time.forced_now_time = Time.now + 60
		val = @cached.accessor
		assert_equal 1, @cached.accessor_counter		
		# In 61, cache is invalidated
		Time.forced_now_time = Time.now + 61
		val = @cached.accessor
		assert_equal 2, @cached.accessor_counter		
	end

	def test_not_default_timeout
		val = @cached.accessor2
		assert_equal 1, @cached.accessor_counter
		Time.forced_now_time = Time.now
		10.times { @cached.accessor2 }
		assert_equal 1, @cached.accessor_counter
		# In 2 minutes, we still cache
		Time.forced_now_time = Time.now + 120
		val = @cached.accessor2
		assert_equal 1, @cached.accessor_counter		
		# In 2m1sec, cache is invalidated
		Time.forced_now_time = Time.now + 121
		val = @cached.accessor2
		assert_equal 2, @cached.accessor_counter		
	end

	def test_invalidate_accessor_by_assignment
		val = @cached.accessor
		assert_equal 1, @cached.accessor_counter

		@cached.accessor = "Hello"
		val = @cached.accessor
		assert_equal 2, @cached.accessor_counter
	end

	def test_invalidate_accessor_explicitely
		val = @cached.accessor
		assert_equal 1, @cached.accessor_counter

		@cached.invalidate_accessor_cache
		val = @cached.accessor
		assert_equal 2, @cached.accessor_counter

		@cached.invalidate_all_accessor_caches
		val = @cached.accessor
		assert_equal 3, @cached.accessor_counter	

		@cached.invalidate_all_caches
		val = @cached.accessor
		assert_equal 4, @cached.accessor_counter			
	end	

	def test_caches_method_with_args
		val = @cached.method_with_args("a","b")
		valA = @cached.method_with_args("a","C")
		assert !(val==valA)
		Time.forced_now_time = Time.now + 1
		val1 = @cached.method_with_args("a","b")
		Time.forced_now_time = nil
		assert_equal val, val1
	end


	def test_invalidate_method_with_args_explicitely
		# Invalidating with another arguments does not work:
		val = @cached.method_with_args("a","b")
		@cached.invalidate_method_with_args_cache("A","B")
		Time.forced_now_time = Time.now + 1
		val1 = @cached.method_with_args("a","b")
		Time.forced_now_time = nil
		assert (val==val1)

		@cached.invalidate_all_caches

		val = @cached.method_with_args("a","b")
		@cached.invalidate_method_with_args_cache("a","b")
		Time.forced_now_time = Time.now + 1
		val1 = @cached.method_with_args("a","b")
		Time.forced_now_time = nil
		assert !(val==val1)

		@cached.invalidate_all_caches

		val = @cached.method_with_args("a","b")
		@cached.invalidate_all_method_with_args_caches
		Time.forced_now_time = Time.now + 1
		val1 = @cached.method_with_args("a","b")
		Time.forced_now_time = nil
		assert !(val==val1)		

		@cached.invalidate_all_caches

		val = @cached.method_with_args("a","b")
		@cached.invalidate_all_caches
		Time.forced_now_time = Time.now + 1
		val1 = @cached.method_with_args("a","b")
		Time.forced_now_time = nil
		assert !(val==val1)		
	end	

	def test_invalidate_all_caches_except
		val = @cached.accessor
		val2 = @cached.accessor2
		valM = @cached.method_with_args("a","b")
		@cached.invalidate_all_caches :except => :method_with_args
		Time.forced_now_time = Time.now + 1
		valM1 = @cached.method_with_args("a","b")
		Time.forced_now_time = nil
		assert (valM==valM1)

		@cached.invalidate_all_caches

		val = @cached.accessor
		val2 = @cached.accessor2
		valM = @cached.method_with_args("a","b")
		@cached.invalidate_all_caches :except => [:method_with_args]
		Time.forced_now_time = Time.now + 1
		valM1 = @cached.method_with_args("a","b")
		Time.forced_now_time = nil
		assert (valM==valM1)		
	end

end
