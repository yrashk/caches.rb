require 'rubygems'
gem 'activesupport'
require 'active_support'

begin
  require 'memcache'
rescue MissingSourceFile, LoadError
end
module Caches

  module Helper

    module Default
      def cachesrb_method_key(name,*args)
        "#{name}#{Marshal.dump(args)}"
      end

      def cachesrb_object_key(name)
        "#{name}"
      end
    end
    module Class
      def cachesrb_method_key(name,*args)
        "#{self.class.name}#{name}#{Marshal.dump(args)}"
      end

      def cachesrb_object_key(name)
        "#{self.class.name}#{name}"
      end
    end
    module Object
      def cachesrb_method_key(name,*args)
        "#{self.name}#{name}#{Marshal.dump(args)}"
      end

      def cachesrb_object_key(name)
        "#{self.name}#{name}"
      end
    end

    module PerID

      protected

      def cachesrb_method_key(name,*args)
        "#{name}#{Marshal.dump(args)}_#{self.id}"
      end

      def cachesrb_object_key(name)
        "#{name}_#{self.id}"
      end

    end
  end

  module Storage
    module Instance

      protected

      attr_accessor :cachesrb_cache

      include ::Caches::Helper::Default

    end

    module Global

      protected

      def cachesrb_cache
        $cachesrb_global_cache ||= {}
      end

      def cachesrb_cache=(v)
        $cachesrb_global_cache=v
      end

      include ::Caches::Helper::Object

    end


    module Class

      protected

      def cachesrb_cache
        @@cachesrb_cache ||= {}
      end

      def cachesrb_cache=(v)
        @@cachesrb_cache=v
      end

      include ::Caches::Helper::Default

    end

    module MemCached

      protected

      def cachesrb_cache
        @cache ||= MemCache::new cachesrb_storage_options[:host], cachesrb_storage_options
      end

      def cachesrb_cache=(v)
        @cache ||= MemCache::new cachesrb_storage_options[:host], cachesrb_storage_options
        @cache=v
      end

      include ::Caches::Helper::Class

    end
  end

  def cached_methods
    @@cached_methods ||= {}
  end

  def caches(name,options = {})
    options.reverse_merge! :timeout => 60
    sanitized_name = name.to_s.delete('?')
    saved_getter = "getter_#{name}"
    saved_setter = "setter_#{name}"
    setter = "#{name}="

    has_setter = public_method_defined? setter.to_sym
    alias_method saved_getter, name
    alias_method(saved_setter, setter.to_sym) if has_setter
    self.cached_methods[name] = options
    module_eval do 
      include Storage::Instance unless protected_method_defined?(:cachesrb_cache)

      public
      
      def self.remove_methods_on_reset?
        false
      end

      def self.remove_variables_on_reset?
        false
      end
      

      def invalidate_all_caches(*opts)
        unless opts.empty?
          opthash = opts.first
          except = opthash[:except]
          if except
            except = [except] unless except.kind_of? Enumerable
            self.cachesrb_cache.each_pair {|k,v| self.cachesrb_cache[k] = nil unless except.any? {|exception| k.starts_with?(exception.to_s)} }
          end
        else
          self.cachesrb_cache = {}
        end
      end

      define_method("invalidate_#{sanitized_name}_cache") do |*args|
        self.cachesrb_cache ||= {}
        key = cachesrb_method_key(name,*args)
        self.cachesrb_cache[key] = nil
      end

      define_method("invalidate_all_#{sanitized_name}_caches") do
        self.cachesrb_cache ||= {}
        key = cachesrb_object_key(name)
        self.cachesrb_cache.keys.each {|k| self.cachesrb_cache[k] = nil if k.starts_with?(key) }
      end			

      define_method("#{name}") do |*args|
        self.cachesrb_cache ||= {}
        key = cachesrb_method_key(name,*args)
        cached = self.cachesrb_cache[key]
        unless cached
          self.cachesrb_cache[key] ||= { :value => self.send(saved_getter.to_sym,*args), :expires_at => Time.now.to_i + options[:timeout]}
          return self.cachesrb_cache[key][:value]
        else
          # unless eval(cached[:value].class.name)  == cached[:value].class
          #   obj = cached[:value]
          #   cached[:value] = eval(obj.class.name).new
          #   obj.instance_variables.each {|v| cached[:value].instance_variable_set("@#{v}",obj.instance_variable_get("@#{v}"))}
          #   obj.instance_methods(false).each {|m| obj.method(m.to_sym).unbind.bind cached[:value]  }
          # end
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
        def remove_methods_on_reset?
          false
        end
        
        def remove_variables_on_reset?
          false
        end
        
        extend ::Caches         
      end
    end
    c.send(:caches, *args)
    c
  end

  def class_cache_storage(storage,options={})
    c = class_eval %{
      class <<self
        include #{storage}
      end
    }
    c.class_eval do 
      protected
      define_method("cachesrb_storage_options") do
        options
      end
    end
  end

  def instance_cache_storage(storage,options={})
    c = class_eval %{
      include #{storage}
    }
    c.class_eval do 
      protected
      define_method("cachesrb_storage_options") do
        options
      end
    end
  end

  def caches?(name)
    self.cached_methods.has_key? name
  end
end
