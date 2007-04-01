require 'caches'

begin
	Kernel.const_get :ActiveRecord
  ActiveRecord::Base.extend Caches
  ActiveRecord::Base.class_eval do
     include CachesStorage::ClassVarById
   end
rescue
end	