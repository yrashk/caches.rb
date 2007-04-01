class String
  def starts_with?(prefix)                                                                                                                     
    prefix = prefix.to_s                                                                                                                       
    self[0, prefix.length] == prefix                                                                                                     
  end
end

module CachesStorage
  module Instance

    protected

    def _propcache
      @propcache
    end

    def _propcache=(v)
      @propcache=v
    end

    def _call_key(name,*args)
      "#{name}#{args.hash}"
    end

    def _object_key(name)
      "#{name}"
    end

  end

  module Global

    protected

    def _propcache
      $cachesrb_propcache ||= {}
    end

    def _propcache=(v)
      $cachesrb_propcache=v
    end

    def _call_key(name,*args)
      "#{self.class.name}#{name}#{args.hash}"
    end

    def _object_key(name)
      "#{self.class.name}#{name}"
    end

  end


  module ClassVarById


    protected

    def _propcache
      @@propcache ||= {}
    end

    def _propcache=(v)
      @@propcache=v
    end

    def _call_key(name,*args)
      "#{name}#{args.hash}_#{self.id}"
    end

    def _object_key(name)
      "#{name}_#{self.id}"
    end


  end
end


module Caches
  def cached_methods
    @@cached_methods ||= {}
  end

  def caches(name,options = {})
    options = { :timeout => 60}.merge options
    sanitized_name = name.to_s.delete('?')
    saved_getter = "getter_#{name}"
    saved_setter = "setter_#{name}"
    setter = "#{name}="

    has_setter = public_method_defined? setter.to_sym
    alias_method saved_getter, name
    alias_method(saved_setter, setter.to_sym) if has_setter
    self.cached_methods[name] = options
    module_eval do 
      include CachesStorage::Instance unless protected_method_defined?(:_propcache)

      public

      def invalidate_all_caches(*opts)
        unless opts.empty?
          opthash = opts.first
          except = opthash[:except]
          if except
            except = [except] unless except.kind_of? Enumerable
            self._propcache.each_pair {|k,v| self._propcache[k] = nil unless except.any? {|exception| k.starts_with?(exception.to_s)} }
          end
        else
          self._propcache = {}
        end
      end

      define_method("invalidate_#{sanitized_name}_cache") do |*args|
        self._propcache ||= {}
        key = _call_key(name,*args)
        self._propcache[key] = nil
      end

      define_method("invalidate_all_#{sanitized_name}_caches") do
        self._propcache ||= {}
        key = _object_key(name)
        self._propcache.keys.each {|k| self._propcache[k] = nil if k.starts_with?(key) }
      end			

      define_method("#{name}") do |*args|
        self._propcache ||= {}
        key = _call_key(name,*args)
        cached = self._propcache[key]
        unless cached
          self._propcache[key] = { :value => self.send(saved_getter.to_sym,*args), :expires_at => Time.now.to_i + options[:timeout]}
          return self._propcache[key][:value]
        else
          unless Time.now.to_i > cached[:expires_at]
            cached[:value]
          else
            self.send "invalidate_#{sanitized_name}_cache".to_sym, *args
            self.send name.to_sym, *args
          end
        end
      end
      if has_setter
        define_method("#{setter}") do |new_val|
          self.send "invalidate_#{sanitized_name}_cache".to_sym
          self.send saved_setter.to_sym, new_val
        end
      end
    end
  end

  def class_caches(*args)
    c = class_eval do
      class <<self
        extend ::Caches 
      end
    end
    c.send(:caches, *args)
    c
  end

  def class_cache_storage(storage)
    class_eval %{
      class <<self
        include #{storage}
      end
    }
  end
  
  def instance_cache_storage(storage)
    class_eval %{
        include #{storage}
    }
  end

  def caches?(name)
    self.cached_methods.has_key? name
  end
end
