
module Wallet
	
	class Entry
		
		attr_reader :date
		attr_reader :amount
		attr_reader :category
		
		def initialize(date = DateTime.now.to_date, amount = 0, category = 'default')
			self.date = date
			self.amount = amount
			@category = category
		end
		
		def date=(date)
			#puts 'set date: ' + date.class.to_s
			
			if date.is_a? String
				@date = Date.parse(date)
			elsif date.is_a? Date
				@date = date
			else
				raise ArgumentError, 'date must be a String or a Date instance'
			end
		end
		
		def amount=(amount)
			if !amount.is_a?(Fixnum) && !amount.is_a?(Float)
				raise ArgumentError, 'amount (' + amount.class.to_s + ') must be a Fixnum or a Float'
			end
			
			@amount = amount
		end
		
		def category=(category)
			if !category.is_a? String
				raise ArgumentError, 'category must be a String'
			end
			
			@category = category
		end
		
		def to_h
			{
				'date' => @date.to_s,
				'amount' => @amount,
				'category' => @category,
			}
		end
		
	end
	
end
