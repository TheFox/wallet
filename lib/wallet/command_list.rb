
module TheFox::Wallet
	
	class ListCommand < Command
		
		NAME = 'list'
		
		def run
			puts
			
			wallet = Wallet.new(@options[:wallet_path])
			entries = wallet.entries(@options[:entry_date], @options[:entry_category].to_s)
			#entries = wallet.entries(@options[:entry_date], @options[:entry_end_date], @options[:entry_category].to_s)
			
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
			
			entries_f = '%' + entries_l.to_s + 's'
			title_f = '%-' + title_l.to_s + 's'
			revenue_f = '%' + revenue_l.to_s + 's'
			expense_f = '%' + expense_l.to_s + 's'
			balance_f = '%' + balance_l.to_s + 's'
			category_f = '%-' + category_l.to_s + 's'
			comment_f = '%-' + comment_l.to_s + 's'
			
			header = ''
			header += '#' * entries_l + '  '
			header += 'Date ' + ' ' * 7
			header += title_f % 'Title' + '  '
			header += revenue_f % 'Revenue' + '  '
			header += expense_f % 'Expense' + '  '
			header += balance_f % 'Balance'
			header += '  ' + category_f % 'Category' if has_category_col
			header += '  ' + comment_f % 'Comment' if has_comment_col
			
			header_l = header.length
			header.sub!(/ +$/, '')
			puts header
			puts '-' * header_l
			
			revenue_total = 0.0
			expense_total = 0.0
			balance_total = 0.0
			previous_date = ''
			entry_no = 0
			entries.sort.each do |day_name, day_items|
				day_items.each do |entry|
					entry_no += 1
					
					title = entry['title']
					title = title[0, 22] + '...' if title.length >= 25
					
					revenue_total += entry['revenue']
					expense_total += entry['expense']
					balance_total += entry['balance']
					
					category = entry['category'] == 'default' ? '' : entry['category']
					has_category = category != ''
					
					comment = entry['comment']
					comment = comment[0, 22] + '...' if comment.length >= 25
					
					out = ''
					out += entries_f % entry_no
					out += '  ' + '%10s' % (entry['date'] == previous_date ? '' : entry['date'])
					out += '  ' + title_f % title
					out += '  ' + revenue_f % (NUMBER_FORMAT % entry['revenue'])
					out += '  ' + expense_f % (NUMBER_FORMAT % entry['expense'])
					out += '  ' + balance_f % (NUMBER_FORMAT % entry['balance'])
					out += '  ' + category_f % category if has_category_col
					out += '  ' + comment_f % comment if has_comment_col
					
					out.sub!(/ +$/, '')
					puts out
					
					previous_date = entry['date']
				end
			end
			puts
			
			out = ''
			out += ' ' * (12 + entries_l)
			out += '  ' + title_f % 'TOTAL'
			out += '  ' + revenue_f % (NUMBER_FORMAT % revenue_total)
			out += '  ' + expense_f % (NUMBER_FORMAT % expense_total)
			out += '  ' + balance_f % (NUMBER_FORMAT % balance_total)
			puts out
		end
		
	end
	
end
