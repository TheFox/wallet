
module TheFox
	module Wallet
		
		class Expense < Wumber
			
			def initialize(number)
				super(-number.abs)
			end
			
		end
		
	end
end
