
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
				revenue_t = STDIN.gets.strip
				if revenue_t.length > 0
					@options[:entry_revenue] = revenue_t.to_s.sub(/,/, '.').to_f.round(NUMBER_ROUND).abs
				end
				
				print "expense: [#{@options[:entry_expense]}] "
				expense_t = STDIN.gets.strip
				if expense_t.length > 0
					@options[:entry_expense] = -expense_t.to_s.sub(/,/, '.').to_f.round(NUMBER_ROUND).abs
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
		
	end
	
end
