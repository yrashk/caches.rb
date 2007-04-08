require 'caches'

begin
	Kernel.const_get :ActiveRecord
  ActiveRecord::Base.extend Caches
  ActiveRecord::Base.instance_cache_storage Caches::Storage::Class
  ActiveRecord::Base.class_eval do
    include Caches::Helper::PerID
  end
rescue
end	