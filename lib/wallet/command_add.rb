
module TheFox::Wallet
	class AddCommand < Command
		
		NAME = 'add'
		
		def run
			if @options[:entry_category].nil?
				@options[:entry_category] = 'default'
			end
			if @options[:is_interactively]
				print "title: [#{@options[:entry_title]}] "
				title_t = STDIN.gets.strip
				if title_t.length > 0
					@options[:entry_title] = title_t
				end
				
				print "date: [#{@options[:entry_date]}] "
				date_t = STDIN.gets.strip
				if date_t.length > 0
					@options[:entry_date] = date_t
				end
				
				print "revenue: [#{@options[:entry_revenue]}] "
				revenue_t = revenue(STDIN.gets.strip)
				if !revenue_t.nil?
					@options[:entry_revenue] = revenue_t
				end
				
				print "expense: [#{@options[:entry_expense]}] "
				expense_t = expense(STDIN.gets.strip)
				if !expense_t.nil?
					@options[:entry_expense] = expense_t
				end
				
				print "category: [#{@options[:entry_category]}] "
				category_t = STDIN.gets.strip
				if category_t.length > 0
					@options[:entry_category] = category_t
				end
				
				print "comment: [#{@options[:entry_comment]}] "
				comment_t = STDIN.gets.strip
				if comment_t.length > 0
					@options[:entry_comment] = comment_t
				end
				
				puts '-' * 20
			end
			
			if @options[:entry_title].nil?
				raise "Option --title is required for command '#{NAME}'"
			end
			
			puts "title:    '#{@options[:entry_title]}'"
			puts "date:      " + Date.parse(@options[:entry_date]).to_s
			puts "revenue:   " + NUMBER_FORMAT % @options[:entry_revenue]
			puts "expense:   " + NUMBER_FORMAT % @options[:entry_expense]
			puts "balance:   " + NUMBER_FORMAT % [@options[:entry_revenue] + @options[:entry_expense]]
			puts "category:  #{@options[:entry_category]}"
			puts "comment:  '#{@options[:entry_comment]}'"
			
			entry = Entry.new(@options[:entry_title], @options[:entry_date], @options[:entry_revenue], @options[:entry_expense], @options[:entry_category], @options[:entry_comment])
			wallet = Wallet.new(@options[:wallet_path])
			wallet.add(entry)
		end
		
		def revenue(revenue_s)
			rv = nil
			if !revenue_s.nil? && revenue_s.length > 0
				rv = eval(revenue_s.to_s.gsub(/,/, '.')).to_f.round(NUMBER_ROUND).abs
			end
			rv
		end
		
		def expense(expense_s)
			rv = nil
			if !expense_s.nil? && expense_s.length > 0
				rv = -eval(expense_s.to_s.gsub(/,/, '.')).to_f.round(NUMBER_ROUND).abs
			end
			rv
		end
		
	end
	
end
