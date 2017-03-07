
module TheFox::Wallet
	
	# List entries. Per default this command lists all entries of today.
	# @TODO Use terminal-table for output? https://github.com/tj/terminal-table
	class ListCommand < Command
		
		NAME = 'list'
		
		def run
			puts
			
			wallet = Wallet.new(@options[:wallet_path])
			entries = wallet.entries(@options[:entry_date], @options[:entry_category].to_s)
			
			# Get max length of all columns.
			entries_l = entries
				.map{ |day_name, day_items| day_items.count }
				.inject{ |sum, n| sum + n }
				.to_s
				.length
			title_l = entries
				.map{ |month_item| month_item[1].map{ |day_item| day_item['title'].length }}
				.flatten
				.max
				.to_i
			revenue_l = entries
				.map{ |month_item| month_item[1].map{ |day_item| (NUMBER_FORMAT % day_item['revenue']).length } }
				.flatten
				.max
				.to_i
			expense_l = entries
				.map{ |month_item| month_item[1].map{ |day_item| (NUMBER_FORMAT % day_item['expense']).length } }
				.flatten
				.max
				.to_i
			balance_l = entries
				.map{ |month_item| month_item[1].map{ |day_item| (NUMBER_FORMAT % day_item['balance']).length } }
				.flatten
				.max
				.to_i
			category_l = entries
				.map{ |month_item| month_item[1].map{ |day_item| day_item['category'].length } }
				.flatten
				.max
				.to_i
			comment_l = entries
				.map{ |month_item| month_item[1].map{ |day_item| day_item['comment'].length } }
				.flatten
				.max
				.to_i
			
			has_category_col = entries.map{ |month_item| month_item[1].map{ |day_item| day_item['category'] } }.flatten.select{ |i| i != 'default' }.count > 0
			has_comment_col = entries
				.map{ |month_item| month_item[1].map{ |day_item| day_item['comment'] } }
				.flatten
				.select{ |i| i != '' }
				.count > 0
			
			# Limit some columns to a maximum length.
			if title_l < 6
				title_l = 6
			end
			if title_l > 25
				title_l = 25
			end
			
			if revenue_l < 7
				revenue_l = 7
			end
			if expense_l < 7
				expense_l = 7
			end
			if balance_l < 7
				balance_l = 7
			end
			if category_l < 8
				category_l = 8
			end
			if comment_l > 25
				comment_l = 25
			end
			
			# Format String for each column.
			entries_f = "%#{entries_l}s"
			title_f = "%-#{title_l}s"
			revenue_f = "%#{revenue_l}s"
			expense_f = "%#{expense_l}s"
			balance_f = "%#{balance_l}s"
			category_f = "%-#{category_l}s"
			comment_f = "%-#{comment_l}s"
			
			# Create a table header.
			header = ''
			header << '#' * entries_l << '  '
			header << 'Date ' << ' ' * 7
			header << title_f % 'Title' << '  '
			header << revenue_f % 'Revenue' << '  '
			header << expense_f % 'Expense' << '  '
			header << balance_f % 'Balance'
			if has_category_col
				header << '  ' << category_f % 'Category'
			end
			if has_comment_col
				header << '  ' << comment_f % 'Comment'
			end
			
			header_l = header.length
			header.sub!(/ +$/, '')
			
			# Print table header.
			puts header
			puts '-' * header_l
			
			# Sums
			revenue_total = 0.0
			expense_total = 0.0
			balance_total = 0.0
			
			# Do not repeat the same date over and over again.
			previous_date = ''
			
			entry_no = 0
			
			# Iterate all days.
			entries.sort.each do |day_name, day_items|
				# Iterate all entries of a day.
				day_items.each do |entry|
					entry_no += 1
					
					title = entry['title']
					if title.length >= 25
						title = title[0, 22] << '...'
					end
					
					revenue_total += entry['revenue']
					expense_total += entry['expense']
					balance_total += entry['balance']
					
					category = entry['category'] == 'default' ? '' : entry['category']
					
					comment = entry['comment']
					if comment.length >= 25
						comment = comment[0, 22] << '...'
					end
					
					out = ''
					out << entries_f % entry_no
					out << '  ' << '%10s' % (entry['date'] == previous_date ? '' : entry['date'])
					out << '  ' << title_f % title
					out << '  ' << revenue_f % (NUMBER_FORMAT % entry['revenue'])
					out << '  ' << expense_f % (NUMBER_FORMAT % entry['expense'])
					out << '  ' << balance_f % (NUMBER_FORMAT % entry['balance'])
					out << '  ' << category_f % category if has_category_col
					out << '  ' << comment_f % comment if has_comment_col
					
					out.sub!(/ +$/, '')
					puts out
					
					previous_date = entry['date']
				end
			end
			puts
			
			out = ''
			out << ' ' * (12 + entries_l)
			out << '  ' << title_f % 'TOTAL'
			out << '  ' << revenue_f % (NUMBER_FORMAT % revenue_total)
			out << '  ' << expense_f % (NUMBER_FORMAT % expense_total)
			out << '  ' << balance_f % (NUMBER_FORMAT % balance_total)
			puts out
		end
		
	end
	
end
