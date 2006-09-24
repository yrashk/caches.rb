class Time
	@@forced_now_time = nil
	
	def self.forced_now_time
		@@forced_now_time
	end
	
	def self.forced_now_time=(time)
		@@forced_now_time = time
	end

	class << self
		def now_with_forcing
			if @@forced_now_time
				@@forced_now_time
			else
				now_without_forcing
			end
		end
		alias_method :now_without_forcing, :now
		alias_method :now, :now_with_forcing
	end
end