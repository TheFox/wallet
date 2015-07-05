
module Wallet
	
	class Entry
		
		attr_reader :title
		attr_reader :date
		attr_reader :revenue
		attr_reader :expense
		attr_reader :balance
		attr_reader :category
		
		def initialize(title = '', date = DateTime.now.to_date, revenue = 0.0, expense = 0.0, category = 'default')
			revenue_t = revenue.to_f
			expense_t = expense.to_f
			
			self.title = title
			self.date = date
			
			@revenue = 0.0
			@expense = 0.0
			@balance = 0.0
			
			if revenue_t < 0 && expense_t == 0
				self.revenue = 0.0
				self.expense = revenue_t
			else
				self.revenue = revenue_t
				self.expense = expense_t
			end
			
			@category = category
		end
		
		def title=(title)
			@title = title.to_s
		end
		
		def date=(date)
			if date.is_a? String
				@date = Date.parse(date)
			elsif date.is_a? Date
				@date = date
			else
				raise ArgumentError, 'date must be a String or a Date instance'
			end
		end
		
		def revenue=(revenue)
			revenue_t = revenue.to_f
			
			if revenue_t < 0
				raise RangeError, 'revenue (' + revenue_t.to_s + ') cannot be < 0. use expense instead!'
			end
			
			@revenue = revenue_t
			calc_balance()
		end
		
		def expense=(expense)
			expense_t = expense.to_f
			
			if expense_t > 0
				raise RangeError, 'expense (' + expense_t.to_s + ') cannot be > 0. use revenue instead!'
			end
			
			@expense = expense_t
			calc_balance()
		end
		
		def category=(category)
			@category = category.to_s
		end
		
		def to_h
			{
				'title' => @title,
				'date' => @date.to_s,
				'revenue' => @revenue,
				'expense' => @expense,
				'balance' => @balance,
				'category' => @category,
			}
		end
		
		private
		
		def calc_balance
			@balance = (@revenue.round(3) + @expense.round(3)).to_f.round(3)
		end
	end
	
end
