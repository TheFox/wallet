
# http://stackoverflow.com/questions/1095789/sub-classing-fixnum-in-ruby

module TheFox
	module Wallet
		
		# Wallet Number
		# Wnumber
		class Wumber
			
			attr_reader :number
			
			def initialize(number)
				puts "init #{self.class}"
				@number = number.to_f
			end
			
			def to_i
				@number.to_i
			end
			
			def method_missing(name, *args, &blk)
				puts "number: #{@number} #{@number.class}"
				puts "method_missing: #{name} #{args}"
				
				# Convert all Wumber back to original.
				args.map!{ |n| n.is_a?(Wumber) ? n.number : n }
				
				ret = @number.send(name, *args, &blk)
				
				# If it's numeric convert it to a Wumber.
				# ret.is_a?(Numeric) ? Wumber.new(ret) : ret
				ret.is_a?(Numeric) ? self.class.new(ret) : ret
				
				# if ret.is_a?(Numeric)
				# 	puts "ret is '#{ret.class}'"
				# 	Wumber.new(ret)
				# else
				# 	puts "ret is is numeric"
				# 	ret
				# end
			end
			
		end
		
	end
end
