require 'caches'

begin
	Kernel.const_get :ActiveRecord
  ActiveRecord::Base.extend CachesConfig
  ActiveRecord::Base.extend Caches
  ActiveRecord::Base.caches_storage = CachesStorage::ClassVarById
rescue
end	