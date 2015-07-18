
# Schmeisst die Fuffies durch den Club und schreit Boah Boah!

require 'yaml'
require 'yaml/store'
require 'csv'
require 'rubyvis'
require 'ostruct'

module Wallet
	
	class Wallet
		
		attr_reader :html_path
		
		def initialize(dir_path = 'wallet')
			@exit = false
			@dir_path = dir_path
			@data_path = File.expand_path('data', @dir_path)
			@html_path = File.expand_path('html', @dir_path)
			
			@has_transaction = false
			@transaction_files = {}
			
			Signal.trap('SIGINT') do
				puts
				puts 'received SIGINT. break ...'
				@exit = true
			end
		end
		
		def add(entry)
			if !entry.is_a? Entry
				raise ArgumentError, 'variable must be a Entry instance'
			end
			
			date = entry.date
			date_s = date.to_s
			dbfile_basename = 'month_' + date.strftime('%Y_%m') + '.yml'
			dbfile_path = File.expand_path(dbfile_basename, @data_path)
			tmpfile_path = dbfile_path + '.tmp'
			file = {
				'meta' => {
					'version' => 1,
					'created_at' => DateTime.now.to_s,
					'updated_at' => DateTime.now.to_s,
				},
				'days' => {}
			}
			
			# puts 'dbfile_basename: ' + dbfile_basename
			# puts 'dbfile_path:     ' + dbfile_path
			# puts 'tmpfile_path:    ' + tmpfile_path
			# puts
			
			if @has_transaction
				if @transaction_files.has_key? dbfile_basename
					file = @transaction_files[dbfile_basename]['file']
				else
					if File.exist? dbfile_path
						file = YAML.load_file(dbfile_path)
						file['meta']['updated_at'] = DateTime.now.to_s
					end
					
					@transaction_files[dbfile_basename] = {
						'basename' => dbfile_basename,
						'path' => dbfile_path,
						'tmp_path' => tmpfile_path,
						'file' => file,
					}
				end
				
				if !file['days'].has_key? date_s
					file['days'][date_s] = []
				end
				
				file['days'][date_s].push entry.to_h
				
				@transaction_files[dbfile_basename]['file'] = file
			else
				create_dirs()
				
				if File.exist? dbfile_path
					file = YAML.load_file(dbfile_path)
					file['meta']['updated_at'] = DateTime.now.to_s
				end
				
				if !file['days'].has_key? date_s
					file['days'][date_s] = []
				end
				
				file['days'][date_s].push entry.to_h
				
				store = YAML::Store.new tmpfile_path
				store.transaction do
					store['meta'] = file['meta']
					store['days'] = file['days']
				end
				
				if File.exist? tmpfile_path
					File.rename tmpfile_path, dbfile_path
				end
			end
		end
		
		def transaction_start
			@has_transaction = true
			@transaction_files = {}
			
			create_dirs()
		end
		
		def transaction_end
			catch(:done) do
				@transaction_files.each do |tr_file_key, tr_file_data|
					throw :done if @exit
					# puts 'keys left: ' + @transaction_files.keys.count.to_s
					# puts 'tr_file_key: ' + tr_file_key
					# puts 'path:        ' + tr_file_data['path']
					# puts 'tmp_path:    ' + tr_file_data['tmp_path']
					# puts
					
					store = YAML::Store.new tr_file_data['tmp_path']
					store.transaction do
						store['meta'] = tr_file_data['file']['meta']
						store['days'] = tr_file_data['file']['days']
					end
					@transaction_files.delete tr_file_key
					
					if File.exist? tr_file_data['tmp_path']
						File.rename tr_file_data['tmp_path'], tr_file_data['path']
					end
				end
			end
			
			@has_transaction = false
			@transaction_files = {}
		end
		
		def sum(year = nil, month = nil, day = nil, category = nil)
			year_s = year.to_i.to_s
			month_f = '%02d' % month.to_i
			day_f = '%02d' % day.to_i
			
			revenue = 0.0
			expense = 0.0
			balance = 0.0
			
			glob = @data_path + '/month_'
			if year == nil && month == nil
				glob += '*.yml'
			elsif year && month == nil
				glob += year_s + '_*.yml'
			elsif year && month
				glob += year_s + '_' + month_f + '.yml'
			end
			
			Dir[glob].each do |file_path|
				data = YAML.load_file(file_path)
				
				if day
					day_key = year_s + '-' + month_f + '-' + day_f
					if data['days'].has_key?(day_key)
						day_sum = calc_day(data['days'][day_key], category)
						revenue += day_sum[:revenue]
						expense += day_sum[:expense]
						balance += day_sum[:balance]
					end
				else
					data['days'].each do |day_name, day_items|
						day_sum = calc_day(day_items, category)
						revenue += day_sum[:revenue]
						expense += day_sum[:expense]
						balance += day_sum[:balance]
					end
				end
			end
			
			revenue = revenue.to_f.round(3)
			expense = expense.to_f.round(3)
			balance = (revenue + expense).round(3)
			
			diff = revenue + expense - balance
			if diff != 0
				raise RuntimeError, 'diff between revenue and expense to balance is ' + diff.to_s
			end
			
			{
				:revenue => revenue,
				:expense => expense,
				:balance => balance,
			}
		end
		
		def sum_category(category)
			sum(nil, nil, nil, category)
		end
		
		def entries(year = nil, month = nil, day = nil, category = nil)
			year_s = year.to_i.to_s
			month_f = '%02d' % month.to_i
			day_f = '%02d' % day.to_i
			
			glob = @data_path + '/month_'
			if year == nil && month == nil
				glob += '*.yml'
			elsif year && month == nil
				glob += year_s + '_*.yml'
			elsif year && month
				glob += year_s + '_' + month_f + '.yml'
			end
			
			# puts 'glob:     ' + glob
			# puts 'year:     ' + '%-10s' % year.class.to_s + '   = "' + year.to_s + '"'
			# puts 'month:    ' + '%-10s' % month.class.to_s + '   = "' + month.to_s + '"'
			# puts 'day:      ' + '%-10s' % day.class.to_s + '   = "' + day.to_s + '"'
			# puts 'category: ' + '%-10s' % category.class.to_s + '   = "' + category.to_s + '"'
			# puts
			
			entries_a = {}
			Dir[glob].each do |file_path|
				data = YAML.load_file(file_path)
				if category.nil? || category.to_s.length == 0
					if day
						day_key = year_s + '-' + month_f + '-' + day_f
						if data['days'].has_key?(day_key)
							entries_a[day_key] = data['days'][day_key]
						end
					else
						entries_a.merge! data['days']
					end
				else
					category = category.to_s.downcase
					if day
						day_key = year_s + '-' + month_f + '-' + day_f
						if data['days'].has_key?(day_key)
							entries_a[day_key] = data['days'][day_key].keep_if{ |day_item|
								day_item['category'].downcase == category
							}
						end
					else
						entries_a.merge! data['days'].map{ |day_name, day_items|
							day_items.keep_if{ |day_item|
								day_item['category'].downcase == category
							}
							[day_name, day_items]
						}.to_h.keep_if{ |day_name, day_items|
							day_items.count > 0
						}
					end
				end
				
			end
			entries_a
		end
		
		def categories
			categories_h = {}
			Dir[@data_path + '/month_*.yml'].each do |file_path|
				data = YAML.load_file(file_path)
				
				data['days'].each do |day_name, day_items|
					day_items.each do |entry|
						category_t = entry['category']
						if category_t.length > 0
							categories_h[category_t] = true
						end
					end
				end
			end
			
			categories_a = categories_h.keys.sort{ |a, b| a.downcase <=> b.downcase }
			default_index = categories_a.index('default')
			if !default_index.nil?
				categories_a.delete_at(categories_a.index('default'))
			end
			categories_a.unshift('default')
			categories_a
		end
		
		def gen_html
			create_dirs()
			
			if !Dir.exist? @html_path
				Dir.mkdir(@html_path)
			end
			
			categories_available = categories()
			
			categories_total_balance = {}
			categories_available.map{ |item| categories_total_balance[item] = 0.0 }
			
			gitignore_file = File.open(@html_path + '/.gitignore', 'w')
			gitignore_file.write '*'
			gitignore_file.close
			
			css_file_path = @html_path + '/style.css'
			css_file = File.open(css_file_path, 'w')
			css_file.write('
				html {
					-webkit-text-size-adjust: none;
				}
				table.list, table.list th, table.list td {
					border: 1px solid black;
				}
				th.left, td.left {
					text-align: left;
				}
				th.right, td.right {
					text-align: right;
				}
				th.first_column {
					min-width: 180px;
					width: 180px;
				}
				th.red, td.red {
					color: #ff0000;
				}
			')
			css_file.close
			
			index_file_path = @html_path + '/index.html'
			index_file = File.open(index_file_path, 'w')
			index_file.write('
				<html>
					<head>
						<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
						<title>' + @dir_path + '</title>
						<link rel="stylesheet" href="style.css" type="text/css" />
					</head>
					<body>
						<h1>' + @dir_path + '</h1>
						<p>Generated @ ' + DateTime.now.strftime('%Y-%m-%d %H:%M:%S') + ' by  <a href="' + ::Wallet::HOMEPAGE + '">' + ::Wallet::NAME + '</a> ' + ::Wallet::VERSION + '</p>
			')
			
			years_total = {}
			years.each do |year|
				year_s = year.to_s
				year_file_name = 'year_' + year_s + '.html'
				year_file_path = @html_path + '/' + year_file_name
				
				year_file = File.open(year_file_path, 'w')
				year_file.write('
					<html>
						<head>
							<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
							<title>' + year_s + ' - ' + @dir_path + '</title>
							<link rel="stylesheet" href="style.css" type="text/css" />
						</head>
						<body>
							<h1><a href="index.html">' + @dir_path + '</a></h1>
							<p>Generated @ ' + DateTime.now.strftime('%Y-%m-%d %H:%M:%S') + ' by  <a href="' + ::Wallet::HOMEPAGE + '">' + ::Wallet::NAME + '</a> ' + ::Wallet::VERSION + '</p>
							
							<h2>Year: ' + year_s + '</h2>
							<table class="list">
								<tr>
									<th class="left">Month</th>
									<th class="right">Revenue</th>
									<th class="right">Expense</th>
									<th class="right">Balance</th>
									<th colspan="' + categories_available.count.to_s + '">' + categories_available.count.to_s + ' Categories</th>
								</tr>
								<tr>
									<th colspan="4">&nbsp;</th>
				')
				categories_available.each do |category|
					year_file.write('<th class="right">' + category + '</th>')
				end
				year_file.write('</tr>')
				
				revenue_year = 0.0
				expense_year = 0.0
				balance_year = 0.0
				categories_year_balance = {}
				categories_available.map{ |item| categories_year_balance[item] = 0.0 }
				year_total = {}
				
				puts 'generate year ' + year_s
				Dir[@data_path + '/month_' + year_s + '_*.yml'].each do |file_path|
					file_name = File.basename(file_path)
					month_n = file_name[11, 2]
					month_file_name = 'month_' + year_s + '_' + month_n + '.html'
					month_file_path = @html_path + '/' + month_file_name
					
					puts "\t" + 'file: ' + month_file_name + ' (from ' + file_name + ')'
					
					month_s = Date.parse('2015-' + month_n + '-15').strftime('%B')
					
					month_file = File.open(month_file_path, 'w')
					month_file.write('
						<html>
							<head>
								<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
								<title>' + month_s + ' ' + year_s + ' - ' + @dir_path + '</title>
								<link rel="stylesheet" href="style.css" type="text/css" />
							</head>
							<body>
								<h1><a href="index.html">' + @dir_path + '</a></h1>
								<p>Generated @ ' + DateTime.now.strftime('%Y-%m-%d %H:%M:%S') + ' by  <a href="' + ::Wallet::HOMEPAGE + '">' + ::Wallet::NAME + '</a> ' + ::Wallet::VERSION + ' from <code>' + file_name + '</code></p>
								
								<h2>Month: ' + month_s + ' <a href="' + year_file_name + '">' + year_s + '</a></h2>
								<table class="list">
									<tr>
										<th class="left">#</th>
										<th class="left">Date</th>
										<th class="left first_column">Title</th>
										<th class="right">Revenue</th>
										<th class="right">Expense</th>
										<th class="right">Balance</th>
										<th class="right">Category</th>
										<th class="left">Comment</th>
									</tr>
					')
					
					revenue_month = 0.0
					expense_month = 0.0
					balance_month = 0.0
					categories_month_balance = {}
					categories_available.map{ |item| categories_month_balance[item] = 0.0 }
					
					entry_n = 0
					data = YAML.load_file(file_path)
					data['days'].sort.each do |day_name, day_items|
						#puts "\t\t" + 'day: ' + day_name
						day_items.each do |entry|
							entry_n += 1
							revenue_month += entry['revenue']
							expense_month += entry['expense']
							balance_month += entry['balance']
							
							categories_year_balance[entry['category']] += entry['balance']
							categories_month_balance[entry['category']] += entry['balance']
							
							revenue_out = entry['revenue'] > 0 ? ::Wallet::NUMBER_FORMAT % entry['revenue'] : '&nbsp;'
							expense_out = entry['expense'] < 0 ? ::Wallet::NUMBER_FORMAT % entry['expense'] : '&nbsp;'
							category_out = entry['category'] == 'default' ? '&nbsp;' : entry['category']
							comment_out = entry['comment'] == '' ? '&nbsp;' : entry['comment']
							
							month_file.write('
								<tr>
									<td valign="top" class="left">' + entry_n.to_s + '</td>
									<td valign="top" class="left">' + Date.parse(entry['date']).strftime('%d.%m.%y') + '</td>
									<td valign="top" class="left">' + entry['title'][0, 50] + '</td>
									<td valign="top" class="right">' + revenue_out + '</td>
									<td valign="top" class="right red">' + expense_out + '</td>
									<td valign="top" class="right ' + (entry['balance'] < 0 ? 'red' : '') + '">' + ::Wallet::NUMBER_FORMAT % entry['balance'] + '</td>
									<td valign="top" class="right">' + category_out + '</td>
									<td valign="top" class="left">' + comment_out + '</td>
								</tr>
							')
						end
					end
					
					revenue_year += revenue_month
					expense_year += expense_month
					balance_year += balance_month
					
					year_total[month_n] = ::OpenStruct.new({
						month: month_n.to_i,
						revenue: revenue_month.round(3),
						expense: expense_month.round(3),
						balance: balance_month.round(3),
					})
					
					balance_class = ''
					if balance_month < 0
						balance_class = 'red'
					end
					month_file.write('
							<tr>
								<th>&nbsp;</th>
								<th>&nbsp;</th>
								<th class="left"><b>TOTAL</b></th>
								<th class="right">' + ::Wallet::NUMBER_FORMAT % revenue_month + '</th>
								<th class="right red">' + ::Wallet::NUMBER_FORMAT % expense_month + '</th>
								<th class="right ' + balance_class + '">' + ::Wallet::NUMBER_FORMAT % balance_month + '</th>
								<th>&nbsp;</th>
								<th>&nbsp;</th>
							</tr>
						</table>')
					month_file.write('</body></html>')
					month_file.close
					
					year_file.write('
						<tr>
							<td class="left"><a href="' + month_file_name + '">' + month_s + '</a></td>
							<td class="right">' + ::Wallet::NUMBER_FORMAT % revenue_month + '</td>
							<td class="right red">' + ::Wallet::NUMBER_FORMAT % expense_month + '</td>
							<td class="right ' + balance_class + '">' + ::Wallet::NUMBER_FORMAT % balance_month + '</td>')
					categories_available.each do |category|
						category_balance = categories_month_balance[category]
						year_file.write('<td class="right ' + (category_balance < 0 ? 'red' : '') + '">' + ::Wallet::NUMBER_FORMAT % category_balance + '</td>')
					end
					year_file.write('</tr>')
				end
				
				year_file.write('
						<tr>
							<th class="left"><b>TOTAL</b></th>
							<th class="right">' + ::Wallet::NUMBER_FORMAT % revenue_year + '</th>
							<th class="right red">' + ::Wallet::NUMBER_FORMAT % expense_year + '</th>
							<th class="right ' + (balance_year < 0 ? 'red' : '') + '">' + ::Wallet::NUMBER_FORMAT % balance_year + '</th>')
				categories_available.each do |category|
					category_balance = categories_year_balance[category]
					year_file.write('<td class="right ' + (category_balance < 0 ? 'red' : '') + '">' + ::Wallet::NUMBER_FORMAT % category_balance + '</td>')
				end
				
				year_file.write('
						</tr>
					</table>
				')
				
				year_total.sort.inject(0.0){ |sum, item| item[1].balance_total = sum + item[1].balance }
				
				width = 500
				height = width.to_f / (16.0 / 9.0)
				x_ticks_n = 12
				y_ticks_n = 5
				
				year_total_take = year_total.sort.map{ |key, item| item }
				y_min = year_total_take.map{ |item| [item.expense.to_i, item.balance.to_i, item.balance_total.to_i] }.flatten.min - 10
				y_max = year_total_take.map{ |item| [item.revenue.to_i, item.balance.to_i, item.balance_total.to_i] }.flatten.max + 10
				x_start = 1
				x_end = 12

				x_data = pv.Scale.linear(x_start, x_end).range(0, width)
				y_data = pv.Scale.linear(y_min, y_max).range(0, height)
				x_ticks = x_data.ticks(x_ticks_n)
				y_ticks = y_data.ticks(y_ticks_n)
				
				vis = pv.Panel.new()
				vis.left(30)
				vis.width(width)
				vis.height(height)
				vis.margin(20)
				vis.right(40)

				panel = vis.add(pv.Panel)
				panel.data(['revenue', 'expense', 'balance', 'balance_total'])

				line = panel.add(pv.Line)
				line.data(year_total_take)

				line.left(lambda{ |d| x_data.scale(d.month.to_i) })
				line.bottom(lambda{ |d, t| y_data.scale(d.send(t)) })
				line.stroke_style(pv.colors('green', 'red', 'black', 'blue').by(pv.parent))
				line.line_width(3)

				label = vis.add(pv.Label)
				label.data(x_ticks)
				label.left(lambda{ |d| x_data.scale(d).to_i - (7 + (d.to_i >= 10 ? 3 : 0)) })
				label.bottom(0)
				label.text_baseline('top')
				label.text_margin(5)
				label.text(lambda{ |d| d.to_i.to_s })

				rule = vis.add(pv.Rule)
				rule.data(y_ticks)
				rule.bottom(lambda{ |d| y_data.scale(d) })
				rule.stroke_style(lambda{ |i| i != 0 ? pv.color('#cccccc') : pv.color('#000000') })

				anchor = rule.anchor('right')
				label = anchor.add(pv.Label)
				#label.visible(lambda{ (self.index & 1) == 0 })
				label.text_margin(7)
				
				rule = vis.add(pv.Rule)
				rule.data(x_ticks)
				rule.left(lambda{ |d| x_data.scale(d) })
				rule.stroke_style(lambda{ |i| pv.color('#cccccc') })
				
				vis.render()
				year_file.write('
					<table>
						<tr>
							<td>' + vis.to_svg + '</td>
							<td valign="top">
								<table>
									<tr><td colspan="2">Legend</td></tr>
									<tr><td style="background: green; width: 20px;">&nbsp;</td><td>Revenue</td></tr>
									<tr><td style="background: red;">&nbsp;</td><td>Expense</td></tr>
									<tr><td style="background: black;">&nbsp;</td><td>Balance</td></tr>
									<tr><td style="background: blue;">&nbsp;</td><td>Balance &#8721;</td></tr>
								</table>
							</td>
						</tr>
					</table>
				')
				
				year_file.write('</body></html>')
				year_file.close
				
				years_total[year_s] = ::OpenStruct.new({
					year: year_s,
					revenue: revenue_year.round(3),
					expense: expense_year.round(3),
					balance: balance_year.round(3),
				})
			end
			
			years_total.sort.inject(0.0){ |sum, item| item[1].balance_total = sum + item[1].balance }
			
			index_file.write('
					<table class="list">
						<tr>
							<th class="left">Year</th>
							<th class="right">Revenue</th>
							<th class="right">Expense</th>
							<th class="right">Balance</th>
							<th class="right">Balance &#8721;</th>
						</tr>')
			years_total.each do |year_name, year_data|
				index_file.write('
					<tr>
						<td class="left"><a href="year_' + year_name + '.html">' + year_name + '</a></td>
						<td class="right">' + ::Wallet::NUMBER_FORMAT % year_data.revenue + '</td>
						<td class="right red">' + ::Wallet::NUMBER_FORMAT % year_data.expense + '</td>
						<td class="right ' + (year_data.balance < 0 ? 'red' : '') + '">' + ::Wallet::NUMBER_FORMAT % year_data.balance + '</td>
						<td class="right ' + (year_data.balance_total < 0 ? 'red' : '') + '">' + ::Wallet::NUMBER_FORMAT % year_data.balance_total + '</td>
					</tr>')
			end
			
			balance_total = years_total.inject(0.0){ |sum, item| sum + item[1].balance }
			
			index_file.write('
					<tr>
						<th class="left"><b>TOTAL</b></th>
						<th class="right">' + ::Wallet::NUMBER_FORMAT % years_total.inject(0.0){ |sum, item| sum + item[1].revenue } + '</th>
						<th class="right red">' + ::Wallet::NUMBER_FORMAT % years_total.inject(0.0){ |sum, item| sum + item[1].expense } + '</th>
						<th class="right ' + (balance_total < 0 ? 'red' : '') + '">' + ::Wallet::NUMBER_FORMAT % balance_total + '</th>
						<th>&nbsp;</th>
					</tr>
				</table>
			')
			
			width = 500
			height = width.to_f / (16.0 / 9.0)
			x_ticks_n = 6
			y_ticks_n = 5
			
			years_total_take = years_total.sort.reverse.map{ |key, item| item }.take(6)
			years_total_take_year_numbers = years_total_take.map{ |item| item.year.to_i }
			
			if years_total_take_year_numbers.count >= 6
				y_min = years_total_take.map{ |item| [item.expense.to_i, item.balance.to_i, item.balance_total.to_i] }.flatten.min - 10
				y_max = years_total_take.map{ |item| [item.revenue.to_i, item.balance.to_i, item.balance_total.to_i] }.flatten.max + 10
				x_start = years_total_take_year_numbers.min
				x_end = years_total_take_year_numbers.max

				x_data = pv.Scale.linear(x_start, x_end).range(0, width)
				y_data = pv.Scale.linear(y_min, y_max).range(0, height)
				x_ticks = x_data.ticks(x_ticks_n)
				y_ticks = y_data.ticks(y_ticks_n)
				
				vis = pv.Panel.new()
				vis.left(30)
				vis.width(width)
				vis.height(height)
				vis.margin(20)
				vis.right(40)

				panel = vis.add(pv.Panel)
				panel.data(['revenue', 'expense', 'balance', 'balance_total'])

				line = panel.add(pv.Line)
				line.data(years_total_take)

				line.left(lambda{ |d| x_data.scale(d.year.to_i) })
				line.bottom(lambda{ |d, t| y_data.scale(d.send(t)) })
				line.stroke_style(pv.colors('green', 'red', 'black', 'blue').by(pv.parent))
				line.line_width(3)

				label = vis.add(pv.Label)
				label.data(x_ticks)
				label.left(lambda{ |d| x_data.scale(d).to_i - 17 })
				label.bottom(0)
				label.text_baseline('top')
				label.text_margin(5)
				label.text(lambda{ |d| d.to_i.to_s })

				rule = vis.add(pv.Rule)
				rule.data(y_ticks)
				rule.bottom(lambda{ |d| y_data.scale(d) })
				rule.stroke_style(lambda{ |i| i != 0 ? pv.color('#cccccc') : pv.color('#000000') })

				anchor = rule.anchor('right')
				label = anchor.add(pv.Label)
				#label.visible(lambda{ (self.index & 1) == 0 })
				label.text_margin(7)
				
				# rule = vis.add(pv.Rule)
				# rule.data(x_ticks)
				# rule.left(lambda{ |d| x_data.scale(d) })
				# rule.stroke_style(lambda{ |i| pv.color('#cccccc') })
				
				vis.render()
				index_file.write('
					<table>
						<tr>
							<td>' + vis.to_svg + '</td>
							<td valign="top">
								<table>
									<tr><td colspan="2">Legend</td></tr>
									<tr><td style="background: green; width: 20px;">&nbsp;</td><td>Revenue</td></tr>
									<tr><td style="background: red;">&nbsp;</td><td>Expense</td></tr>
									<tr><td style="background: black;">&nbsp;</td><td>Balance</td></tr>
									<tr><td style="background: blue;">&nbsp;</td><td>Balance &#8721;</td></tr>
								</table>
							</td>
						</tr>
					</table>
				')
			end
			
			index_file.write('
					</body>
				</html>
			')
			index_file.write('')
			index_file.close
		end
		
		def import_csv_file(file_path)
			transaction_start()
			
			catch(:done) do
				row_n = 0
				CSV.foreach(file_path) do |row|
					throw :done if @exit
					row_n += 1
					
					date = ''
					title = ''
					revenue = 0.0
					expense = 0.0
					category = ''
					comment = ''
					
					print 'import row ' + row_n.to_s + "\r"
					
					if row.count < 2
						raise IndexError, 'invalid row ' + row_n.to_s + ': "' + row.join(',') + '"'
					elsif row.count >= 2
						date, title, revenue, expense, category, comment = row
						revenue = revenue.to_f
						if revenue < 0
							expense = revenue
							revenue = 0.0
						end
					end
					
					add Entry.new(title, date, revenue, expense, category, comment)
					
				end
				
				puts
				puts 'save data ...'
			end
			
			transaction_end()
		end
		
		def export_csv_file(file_path)
			csv_file = File.open(file_path, 'w')
			csv_file.puts 'Date,Title,Revenue,Expense,Balance,Category,Comment'
			
			Dir[@data_path + '/month_*.yml'].each do |yaml_file_path|
				puts 'export ' + File.basename(yaml_file_path)
				
				data = YAML.load_file(yaml_file_path)
				
				data['days'].each do |day_name, day_items|
					day_items.each do |entry|
						out = [
							entry['date'],
							'"'+entry['title']+'"',
							::Wallet::NUMBER_FORMAT % entry['revenue'],
							::Wallet::NUMBER_FORMAT % entry['expense'],
							::Wallet::NUMBER_FORMAT % entry['balance'],
							'"'+entry['category']+'"',
							'"'+entry['comment']+'"',
						].join(',')
						
						csv_file.puts out
					end
				end
			end
			
			csv_file.close
		end
		
		private
		
		def create_dirs
			if !Dir.exist? @dir_path
				Dir.mkdir(@dir_path)
			end
			
			if !Dir.exist? @data_path
				Dir.mkdir(@data_path)
			end
		end
		
		def calc_day(day_a, category = nil)
			revenue = 0
			expense = 0
			balance = 0
			if category
				category.to_s.downcase!
				
				day_a.each do |entry|
					if entry['category'] == category
						revenue += entry['revenue']
						expense += entry['expense']
						balance += entry['balance']
					end
				end
			else
				day_a.each do |entry|
					revenue += entry['revenue']
					expense += entry['expense']
					balance += entry['balance']
				end
			end
			
			{
				:revenue => revenue,
				:expense => expense,
				:balance => balance,
			}
		end
		
		def years
			Dir[@data_path + '/month_*.yml'].map{ |file_path| File.basename(file_path)[6, 4].to_i }.uniq
		end
		
	end
	
end
