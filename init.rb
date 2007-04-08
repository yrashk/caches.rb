require 'caches'

begin
  Kernel.const_get :ActiveRecord
  ActiveRecord::Base.extend Caches
  ActiveRecord::Base.instance_cache_storage Caches::Storage::Class
  ActiveRecord::Base.class_eval do
    include Caches::Helper::PerID

    # def self.remove_methods_on_reset?
    #   false
    # end
    # 
    # def self.remove_variables_on_reset?
    #   false
    # end
    # 
    # def self.reset_subclasses #:nodoc:
    #   nonreloadables = []
    #   subclasses.each do |klass|
    #     unless Dependencies.autoloaded? klass
    #       nonreloadables << klass
    #       next
    #     end
    #     klass.instance_variables.each { |var| klass.send(:remove_instance_variable, var) } if klass.remove_variables_on_reset?
    #     klass.instance_methods(false).each { |m| klass.send :undef_method, m } if klass.remove_methods_on_reset?
    #   end
    #   @@subclasses = {}
    #   nonreloadables.each { |klass| (@@subclasses[klass.superclass] ||= []) << klass }
    # end

  end

rescue
end