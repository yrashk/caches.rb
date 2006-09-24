class String
	def starts_with?(prefix)                                                                                                                     
          prefix = prefix.to_s                                                                                                                       
          self[0, prefix.length] == prefix                                                                                                     
  end
end

module Caches
	def caches(name,options = { :timeout => 60})
		sanitized_name = name.to_s.delete('?')
		saved_getter = "getter_#{name}"
		saved_setter = "setter_#{name}"
		setter = "#{name}="

		has_setter = new.respond_to? setter.to_sym

		module_eval "alias #{saved_getter} #{name}"
		module_eval "alias #{saved_setter} #{setter.to_sym}" if has_setter
		module_eval do 
			define_method("invalidate_all_caches") do  |*opts|
				unless opts.empty?
					opthash = opts.first
					except = opthash[:except]
					if except
						except = [except] unless except.kind_of? Enumerable
						@propcache.each_pair do |k,v|
							@propcache[k] = nil unless except.any? {|exception| k.starts_with?(exception.to_s)}
						end
					end
				else
					@propcache = {}
				end
			end
			define_method("invalidate_#{sanitized_name}_cache") do |*args|
				@propcache ||= {}
				key = name.to_s+args.hash.to_s
				@propcache[key] = nil
			end
			define_method("invalidate_all_#{sanitized_name}_caches") do
				@propcache ||= {}
				key = name.to_s
				@propcache.keys.each {|k| @propcache[k] = nil if k.starts_with?(key) }
			end			
			define_method("#{name}") do |*args| # FIXME: this implementation smells bad
				@propcache ||= {}
				key = name.to_s+args.hash.to_s
				cached = @propcache[key]
				unless cached
					@propcache[key] = { :value => self.send(saved_getter.to_sym,*args), :expires_at => Time.now.to_i + options[:timeout]}
					return @propcache[key][:value]
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
end