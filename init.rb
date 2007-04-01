require 'caches'

begin
	Kernel.const_get :ActiveRecord
  ActiveRecord::Base.extend Caches
  ActiveRecord::Base.instance_cache_storage CachesStorage::ClassVarById
rescue
end	