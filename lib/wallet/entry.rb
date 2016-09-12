
require 'uuid'
require 'date'

module TheFox
	module Wallet
		
		class Entry
			
			attr_reader :id
			attr_reader :title
			attr_reader :date
			attr_reader :revenue
			attr_reader :expense
			attr_reader :balance
			attr_reader :category
			attr_reader :comment
			
			def initialize(id = nil, title = nil, date = nil, revenue = nil, expense = nil, category = nil, comment = nil)
				if !id
					uuid = UUID.new
					id = uuid.generate
				end
				date ||= Date.today
				revenue ||= 0.0
				expense ||= 0.0
				category ||= 'default'
				
				self.id = id
				self.title = title
				self.date = date
				
				@revenue = 0.0
				@expense = 0.0
				@balance = 0.0
				
				revenue_t = revenue.to_f
				expense_t = expense.to_f
				if revenue_t < 0 && expense_t == 0
					self.revenue = 0.0
					self.expense = revenue_t
				else
					self.revenue = revenue_t
					self.expense = expense_t
				end
				
				self.category = category
				self.comment = comment
			end
			
			def id=(id)
				@id = id
			end
			
			def title=(title)
				@title = title.to_s
			end
			
			def date=(date)
				case date
				when String
					@date = Date.parse(date)
				when Fixnum
					@date = Time.at(date).to_date
				when Date
					@date = date
				else
					raise ArgumentError, "Wrong class: #{date.class}"
				end
			end
			
			def revenue=(revenue)
				revenue_t = revenue.to_f
				
				if revenue_t < 0
					raise RangeError, 'revenue (' + revenue_t.to_s + ') cannot be < 0. use expense instead!'
				end
				
				@revenue = revenue_t
				calc_balance
			end
			
			def expense=(expense)
				expense_t = expense.to_f
				
				if expense_t > 0
					raise RangeError, 'expense (' + expense_t.to_s + ') cannot be > 0. use revenue instead!'
				end
				
				@expense = expense_t
				calc_balance
			end
			
			def category=(category)
				@category = category.nil? ? 'default' : category.to_s
			end
			
			def comment=(comment)
				@comment = comment.nil? ? '' : comment.to_s
			end
			
			def to_h
				{
					'id' => @id,
					'title' => @title,
					'date' => @date.to_s,
					'revenue' => @revenue,
					'expense' => @expense,
					'balance' => @balance,
					'category' => @category,
					'comment' => @comment,
				}
			end
			
			def self.from_h(h)
				id = h['id']
				title = h['title']
				date = h['date']
				revenue = h['revenue']
				expense = h['expense']
				# balance = h['balance']
				category = h['category']
				comment = h['comment']
				
				self.new(id, title, date, revenue, expense, category, comment)
			end
			
			private
			
			def calc_balance
				@balance = (@revenue.round(NUMBER_ROUND) + @expense.round(NUMBER_ROUND)).to_f.round(NUMBER_ROUND)
			end
			
		end
		
	end
end
