require 'caches'

begin
	Kernel.const_get :ActiveRecord
	ActiveRecord::Base.extend Caches
rescue
end	