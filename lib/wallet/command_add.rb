
require 'date'

module TheFox::Wallet
	
	# Add a new Entry.
	class AddCommand < Command
		
		NAME = 'add'
		
		def run
			if @options[:entry_category].nil?
				@options[:entry_category] = 'default'
			end
			
			if @options[:is_interactively]
				# Interactive User Input
				
				print "title: [#{@options[:entry_title]}] "
				title_t = STDIN.gets.strip
				if title_t.length > 0
					# Search for '%d' in title.
					if @options[:entry_title] =~ /%d/
						# Like sprintf.
						@options[:entry_title] = @options[:entry_title] % title_t.split(',').map{ |s| s.strip }
					else
						@options[:entry_title] = title_t
					end
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
			
			# --force option
			# --id    option
			is_unique = !@options[:force] && @options[:entry_id]
			
			puts "id:       '#{@options[:entry_id]}'"
			puts "title:    '#{@options[:entry_title]}'"
			puts "date:      " << Date.parse(@options[:entry_date]).to_s
			puts "revenue:   " << NUMBER_FORMAT % @options[:entry_revenue]
			puts "expense:   " << NUMBER_FORMAT % @options[:entry_expense]
			puts "balance:   " << NUMBER_FORMAT % [@options[:entry_revenue] + @options[:entry_expense]]
			puts "category:  #{@options[:entry_category]}"
			puts "comment:  '#{@options[:entry_comment]}'"
			puts "force:    #{@options[:force] ? 'YES' : 'NO'}"
			puts "unique:   #{is_unique ? 'YES' : 'NO'} (#{is_unique})"
			
			# Create new Entry.
			entry = Entry.new(@options[:entry_id], @options[:entry_title], @options[:entry_date], @options[:entry_revenue], @options[:entry_expense], @options[:entry_category], @options[:entry_comment])
			
			# Initialize Wallet.
			wallet = Wallet.new(@options[:wallet_path])
			
			# Add Entry to Wallet.
			added = wallet.add(entry, is_unique)
			
			puts "added:    #{added ? 'YES' : 'NO'}"
			
			added ? 0 : 1
		end
		
		# @TODO replace with Wumber.
		def revenue(revenue_s)
			if !revenue_s.nil? && revenue_s.length > 0
				# Replace , with . in numbers. '1,23' means '1.23'.
				# eval the revenue so calculations are solved.
				eval(revenue_s.to_s.gsub(/,/, '.')).to_f.round(NUMBER_ROUND).abs
			end
		end
		
		# @TODO replace with Wumber.
		def expense(expense_s)
			if !expense_s.nil? && expense_s.length > 0
				# Replace , with . in numbers. '1,23' means '1.23'.
				# eval the revenue so calculations are solved.
				# Expenses are always minus.
				-eval(expense_s.to_s.gsub(/,/, '.')).to_f.round(NUMBER_ROUND).abs
			end
		end
		
	end
	
end
