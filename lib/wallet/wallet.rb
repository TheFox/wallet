
# Schmeisst die Fuffies durch den Club und schreit Boah Boah!

require 'logger'
require 'yaml'
require 'yaml/store'
require 'csv'

# OpenStruct use to generate HTML.
require 'ostruct'

# require 'pp'


module TheFox
	module Wallet
		
		class Wallet
			
			attr_writer :logger
			attr_reader :html_path
			
			def initialize(dir_path = 'wallet')
				@exit = false
				@logger = nil
				@dir_path = dir_path
				@data_path = File.expand_path('data', @dir_path)
				@html_path = File.expand_path('html', @dir_path)
				@tmp_path = File.expand_path('tmp', @dir_path)
				
				@has_transaction = false
				@transaction_files = Hash.new
				
				@entries_by_ids = nil
				
				Signal.trap('SIGINT') do
					puts
					puts 'received SIGINT. break ...'
					@exit = true
				end
			end
			
			def add(entry, is_unique = false)
				if !entry.is_a?(Entry)
					raise ArgumentError, 'variable must be a Entry instance'
				end
				
				# puts "add, id #{entry.id}"
				# puts "add, is_unique    #{is_unique}"
				# puts "add, entry_exist? #{entry_exist?(entry)}"
				# puts
				if is_unique && entry_exist?(entry)
					return false
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
					'days' => Hash.new,
				}
				
				# puts 'dbfile_basename: ' + dbfile_basename
				# puts 'dbfile_path:     ' + dbfile_path
				# puts 'tmpfile_path:    ' + tmpfile_path
				# puts
				
				if @has_transaction
					if @transaction_files.has_key?(dbfile_basename)
						file = @transaction_files[dbfile_basename]['file']
					else
						if File.exist?(dbfile_path)
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
					
					if file['days'].is_a?(Array)
						file['days'] = Hash.new
					end
					if !file['days'].has_key?(date_s)
						file['days'][date_s] = Array.new
					end
					
					file['days'][date_s].push(entry.to_h)
					
					@transaction_files[dbfile_basename]['file'] = file
				else
					create_dirs
					
					if File.exist?(dbfile_path)
						file = YAML.load_file(dbfile_path)
						file['meta']['updated_at'] = DateTime.now.to_s
					end
					
					if file['days'].is_a?(Array)
						file['days'] = Hash.new
					end
					if !file['days'].has_key?(date_s)
						file['days'][date_s] = Array.new
					end
					
					file['days'][date_s].push(entry.to_h)
					
					store = YAML::Store.new(tmpfile_path)
					store.transaction do
						store['meta'] = file['meta']
						store['days'] = file['days']
					end
					
					if File.exist?(tmpfile_path)
						File.rename(tmpfile_path, dbfile_path)
					end
				end
				
				if @entries_by_ids.nil?
					@entries_by_ids = Hash.new
				end
				@entries_by_ids[entry.id] = entry
				
				true
			end
			
			def transaction_start
				@has_transaction = true
				@transaction_files = Hash.new
				
				create_dirs
			end
			
			def transaction_end
				catch(:done) do
					@transaction_files.each do |tr_file_key, tr_file_data|
						if @exit
							throw :done
						end
						# puts 'keys left: ' + @transaction_files.keys.count.to_s
						# puts 'tr_file_key: ' + tr_file_key
						# puts 'path:        ' + tr_file_data['path']
						# puts 'tmp_path:    ' + tr_file_data['tmp_path']
						# puts
						
						store = YAML::Store.new(tr_file_data['tmp_path'])
						store.transaction do
							store['meta'] = tr_file_data['file']['meta']
							store['days'] = tr_file_data['file']['days']
						end
						@transaction_files.delete(tr_file_key)
						
						if File.exist?(tr_file_data['tmp_path'])
							File.rename(tr_file_data['tmp_path'], tr_file_data['path'])
						end
					end
				end
				
				@has_transaction = false
				@transaction_files = Hash.new
			end
			
			def sum(year = nil, month = nil, day = nil, category = nil)
				year_s = year.to_i.to_s
				month_f = '%02d' % month.to_i
				day_f = '%02d' % day.to_i
				
				revenue = 0.0
				expense = 0.0
				balance = 0.0
				
				glob = File.expand_path('month_', @data_path)
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
				
				revenue = revenue.to_f.round(NUMBER_ROUND)
				expense = expense.to_f.round(NUMBER_ROUND)
				balance = (revenue + expense).round(NUMBER_ROUND)
				
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
			
			def entries(begin_date, category = nil)
				begin_year, begin_month, begin_day = begin_date.split('-').map{ |n| n.to_i }
				
				begin_year_s = begin_year.to_i.to_s
				begin_month_f = '%02d' % begin_month.to_i
				begin_day_f = '%02d' % begin_day.to_i
				
				glob = File.expand_path('month_', @data_path)
				if begin_year == nil && begin_month == nil
					glob += '*.yml'
				elsif begin_year && begin_month == nil
					glob += "#{begin_year_s}_*.yml"
				elsif begin_year && begin_month
					glob += "#{begin_year_s}_#{begin_month_f}.yml"
				end
				
				category = category.to_s.downcase
				
				# puts 'glob:     ' + glob
				# puts 'begin_year:     ' + '%-10s' % begin_year.class.to_s + '   = "' + begin_year.to_s + '"'
				# puts 'begin_month:    ' + '%-10s' % begin_month.class.to_s + '   = "' + begin_month.to_s + '"'
				# puts 'begin_day:      ' + '%-10s' % begin_day.class.to_s + '   = "' + begin_day.to_s + '"'
				# puts 'category:       ' + '%-10s' % category.class.to_s + '   = "' + category.to_s + '"'
				# puts
				
				entries_a = Hash.new
				Dir[glob].each do |file_path|
					#puts "path: #{file_path}"
					
					data = YAML.load_file(file_path)
					if category.length == 0
						if begin_day
							day_key = begin_year_s + '-' + begin_month_f + '-' + begin_day_f
							if data['days'].has_key?(day_key)
								entries_a[day_key] = data['days'][day_key]
							end
						else
							entries_a.merge!(data['days'])
						end
					else
						if begin_day
							day_key = begin_year_s + '-' + begin_month_f + '-' + begin_day_f
							if data['days'].has_key?(day_key)
								entries_a[day_key] = data['days'][day_key].keep_if{ |day_item|
									day_item['category'].downcase == category
								}
							end
						else
							entries_a.merge!(data['days'].map{ |day_name, day_items|
								day_items.keep_if{ |day_item|
									day_item['category'].downcase == category
								}
								[day_name, day_items]
							}.to_h.keep_if{ |day_name, day_items|
								day_items.count > 0
							})
						end
					end
					
				end
				entries_a
			end
			
			def categories
				categories_h = Hash.new
				Dir[File.expand_path('month_*.yml', @data_path)].each do |file_path|
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
				create_dirs
				
				html_options_path = File.expand_path('options.yml', @html_path)
				html_options = {
					'meta' => {
						'version' => 1,
						'created_at' => DateTime.now.to_s,
						'updated_at' => DateTime.now.to_s,
					},
					'changes' => Hash.new,
				}
				if Dir.exist?(@html_path)
					if File.exist?(html_options_path)
						html_options = YAML.load_file(html_options_path)
						html_options['meta']['updated_at'] = DateTime.now.to_s
					end
				else
					Dir.mkdir(@html_path)
				end
				
				categories_available = categories
				
				categories_total_balance = Hash.new
				categories_available.map{ |item| categories_total_balance[item] = 0.0 }
				
				gitignore_file = File.open(File.expand_path('.gitignore', @html_path), 'w')
				gitignore_file.write('*')
				gitignore_file.close
				
				css_file_path = File.expand_path('style.css', @html_path)
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
				
				index_file_path = File.expand_path('index.html', @html_path)
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
							<p>Generated @ ' + DateTime.now.strftime('%Y-%m-%d %H:%M:%S') + ' by  <a href="' + ::TheFox::Wallet::HOMEPAGE + '">' + ::TheFox::Wallet::NAME + '</a> ' + ::TheFox::Wallet::VERSION + '</p>
				')
				
				years_total = Hash.new
				years.each do |year|
					year_s = year.to_s
					year_file_name = 'year_' + year_s + '.html'
					year_file_path = File.expand_path(year_file_name, @html_path)
					
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
								<p>Generated @ ' + DateTime.now.strftime('%Y-%m-%d %H:%M:%S') + ' by  <a href="' + ::TheFox::Wallet::HOMEPAGE + '">' + ::TheFox::Wallet::NAME + '</a> ' + ::TheFox::Wallet::VERSION + '</p>
								
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
					categories_year_balance = Hash.new
					categories_available.map{ |item| categories_year_balance[item] = 0.0 }
					year_total = Hash.new
					
					puts 'generate year ' + year_s
					Dir[File.expand_path('month_' + year_s + '_*.yml', @data_path)].each do |file_path|
						file_name = File.basename(file_path)
						month_n = file_name[11, 2]
						month_file_name = 'month_' + year_s + '_' + month_n + '.html'
						month_file_path = File.expand_path(month_file_name, @html_path)
						
						month_s = Date.parse('2015-' + month_n + '-15').strftime('%B')
						
						revenue_month = 0.0
						expense_month = 0.0
						balance_month = 0.0
						categories_month_balance = Hash.new
						categories_available.map{ |item| categories_month_balance[item] = 0.0 }
						
						entry_n = 0
						data = YAML.load_file(file_path)
						
						generate_html = false
						if html_options['changes'].has_key?(file_name)
							if html_options['changes'][file_name]['updated_at'] != data['meta']['updated_at']
								html_options['changes'][file_name]['updated_at'] = data['meta']['updated_at']
								generate_html = true
							end
						else
							html_options['changes'][file_name] = {
								'updated_at' => data['meta']['updated_at'],
							}
							generate_html = true
						end
						if !File.exist?(month_file_path)
							generate_html = true
						end
						
						if generate_html
							puts "\t" + 'file: ' + month_file_name + ' (from ' + file_name + ')'
							
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
										<p>Generated @ ' + DateTime.now.strftime('%Y-%m-%d %H:%M:%S') + ' by  <a href="' + ::TheFox::Wallet::HOMEPAGE + '">' + ::TheFox::Wallet::NAME + '</a> ' + ::TheFox::Wallet::VERSION + ' from <code>' + file_name + '</code></p>
										
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
						end
						
						data['days'].sort.each do |day_name, day_items|
							#puts "\t\t" + 'day: ' + day_name
							day_items.each do |entry|
								entry_n += 1
								revenue_month += entry['revenue']
								expense_month += entry['expense']
								balance_month += entry['balance']
								
								categories_year_balance[entry['category']] += entry['balance']
								categories_month_balance[entry['category']] += entry['balance']
								
								revenue_out = entry['revenue'] > 0 ? ::TheFox::Wallet::NUMBER_FORMAT % entry['revenue'] : '&nbsp;'
								expense_out = entry['expense'] < 0 ? ::TheFox::Wallet::NUMBER_FORMAT % entry['expense'] : '&nbsp;'
								category_out = entry['category'] == 'default' ? '&nbsp;' : entry['category']
								comment_out = entry['comment'] == '' ? '&nbsp;' : entry['comment']
								
								if generate_html
									month_file.write('
										<tr>
											<td valign="top" class="left">' + entry_n.to_s + '</td>
											<td valign="top" class="left">' + Date.parse(entry['date']).strftime('%d.%m.%y') + '</td>
											<td valign="top" class="left">' + entry['title'][0, 50] + '</td>
											<td valign="top" class="right">' + revenue_out + '</td>
											<td valign="top" class="right red">' + expense_out + '</td>
											<td valign="top" class="right ' + (entry['balance'] < 0 ? 'red' : '') + '">' + ::TheFox::Wallet::NUMBER_FORMAT % entry['balance'] + '</td>
											<td valign="top" class="right">' + category_out + '</td>
											<td valign="top" class="left">' + comment_out + '</td>
										</tr>
									')
								end
							end
						end
						
						revenue_year += revenue_month
						expense_year += expense_month
						balance_year += balance_month
						
						revenue_month_r = revenue_month.round(NUMBER_ROUND)
						expense_month_r = expense_month.round(NUMBER_ROUND)
						balance_month_r = balance_month.round(NUMBER_ROUND)
						
						year_total[month_n] = ::OpenStruct.new({
							month: month_n.to_i,
							month_s: '%02d' % month_n.to_i,
							revenue: revenue_month_r,
							expense: expense_month_r,
							balance: balance_month_r,
						})
						
						balance_class = ''
						if balance_month < 0
							balance_class = 'red'
						end
						if generate_html
							month_file.write('
									<tr>
										<th>&nbsp;</th>
										<th>&nbsp;</th>
										<th class="left"><b>TOTAL</b></th>
										<th class="right">' + ::TheFox::Wallet::NUMBER_FORMAT % revenue_month + '</th>
										<th class="right red">' + ::TheFox::Wallet::NUMBER_FORMAT % expense_month + '</th>
										<th class="right ' + balance_class + '">' + ::TheFox::Wallet::NUMBER_FORMAT % balance_month + '</th>
										<th>&nbsp;</th>
										<th>&nbsp;</th>
									</tr>
								</table>')
							month_file.write('</body></html>')
							month_file.close
						end
						
						year_file.write('
							<tr>
								<td class="left"><a href="' + month_file_name + '">' + month_s + '</a></td>
								<td class="right">' + ::TheFox::Wallet::NUMBER_FORMAT % revenue_month + '</td>
								<td class="right red">' + ::TheFox::Wallet::NUMBER_FORMAT % expense_month + '</td>
								<td class="right ' + balance_class + '">' + ::TheFox::Wallet::NUMBER_FORMAT % balance_month + '</td>')
						categories_available.each do |category|
							category_balance = categories_month_balance[category]
							year_file.write('<td class="right ' + (category_balance < 0 ? 'red' : '') + '">' + ::TheFox::Wallet::NUMBER_FORMAT % category_balance + '</td>')
						end
						year_file.write('</tr>')
					end
					
					year_total.sort.inject(0.0){ |sum, item| item[1].balance_total = (sum + item[1].balance).round(NUMBER_ROUND) }
					
					year_file.write('
							<tr>
								<th class="left"><b>TOTAL</b></th>
								<th class="right">' + ::TheFox::Wallet::NUMBER_FORMAT % revenue_year + '</th>
								<th class="right red">' + ::TheFox::Wallet::NUMBER_FORMAT % expense_year + '</th>
								<th class="right ' + (balance_year < 0 ? 'red' : '') + '">' + ::TheFox::Wallet::NUMBER_FORMAT % balance_year + '</th>')
					categories_available.each do |category|
						category_balance = categories_year_balance[category]
						year_file.write('<td class="right ' + (category_balance < 0 ? 'red' : '') + '">' + ::TheFox::Wallet::NUMBER_FORMAT % category_balance + '</td>')
					end
					
					year_file.write('
							</tr>
						</table>
					')
					
					year_file.write("<p><img src=\"year_#{year_s}.png\"></p>")
					year_file.write('</body></html>')
					year_file.close
					
					yeardat_file_path = File.expand_path("year_#{year_s}.dat", @tmp_path)
					yeardat_file = File.new(yeardat_file_path, 'w')
					yeardat_file.write(year_total
						.map{ |k, m| "#{year_s}-#{m.month_s} #{m.revenue} #{m.expense} #{m.balance} #{m.balance_total} #{m.balance_total}" }
						.join("\n"))
					yeardat_file.close
					
					# year_max = year_total
					# 	.map{ |k, m| [m.revenue, m.balance, m.balance_total] }
					# 	.flatten
					# 	.max
					# 	.to_i
					
					# year_min = year_total
					# 	.map{ |k, m| [m.expense, m.balance, m.balance_total] }
					# 	.flatten
					# 	.min
					# 	.to_i
					# 	.abs
					
					# year_max_rl = year_max.to_s.length - 2
					# year_max_r = year_max.round(-year_max_rl)
					# year_max_d = year_max_r - year_max
					# year_max_r = year_max_r + 5 * 10 ** (year_max_rl - 1) if year_max_r < year_max
					# year_max_r += 100
					
					# year_min_rl = year_min.to_s.length - 2
					# year_min_r = year_min.round(-year_min_rl)
					# year_min_d = year_min_r - year_min
					# year_min_r = year_min_r + 5 * 10 ** (year_min_rl - 1) if year_min_r < year_min
					# year_min_r += 100
					
					# puts "#{year_max} #{year_max.to_s.length} #{year_max_r} #{year_max_rl}"
					# puts "#{year_min} #{year_min.to_s.length} #{year_min_r} #{year_min_rl}"
					
					gnuplot_file = File.new(File.expand_path("year_#{year_s}.gp", @tmp_path), 'w')
					gnuplot_file.puts("set title 'Year #{year_s}'")
					gnuplot_file.puts("set xlabel 'Months'")
					gnuplot_file.puts("set ylabel 'Euro'")
					gnuplot_file.puts("set grid")
					gnuplot_file.puts("set key below center horizontal noreverse enhanced autotitle box dashtype solid")
					gnuplot_file.puts("set tics out nomirror")
					gnuplot_file.puts("set border 3 front linetype black linewidth 1.0 dashtype solid")
					
					gnuplot_file.puts("set timefmt '%Y-%m'")
					gnuplot_file.puts("set xdata time")
					gnuplot_file.puts("set format x '%b'")
					gnuplot_file.puts("set xrange ['#{year_s}-01-01':'#{year_s}-12-31']")
					gnuplot_file.puts("set xtics '#{year_s}-01-01', 2592000, '#{year_s}-12-31'")
					# gnuplot_file.puts("set yrange [-#{year_min_r}:#{year_max_r}]")
					gnuplot_file.puts("set autoscale y")
					
					gnuplot_file.puts("set style line 1 linecolor rgb '#00ff00' linewidth 2 linetype 1 pointtype 2")
					gnuplot_file.puts("set style line 2 linecolor rgb '#ff0000' linewidth 2 linetype 1 pointtype 2")
					gnuplot_file.puts("set style line 3 linecolor rgb '#000000' linewidth 2 linetype 1 pointtype 2")
					gnuplot_file.puts("set style line 4 linecolor rgb '#0000ff' linewidth 2 linetype 1 pointtype 2")
					gnuplot_file.puts("set style data linespoints")
					gnuplot_file.puts("set terminal png enhanced")
					gnuplot_file.puts("set output '" << File.expand_path("year_#{year_s}.png", @html_path) << "'")
					gnuplot_file.puts("plot sum = 0, \\")
					gnuplot_file.puts("\t'#{yeardat_file_path}' using 1:2 linestyle 1 title 'Revenue', \\")
					gnuplot_file.puts("\t'' using 1:3 linestyle 2 title 'Expense', \\")
					gnuplot_file.puts("\t'' using 1:4 linestyle 3 title 'Balance', \\")
					gnuplot_file.puts("\t'' using 1:5 linestyle 4 title '∑ Balance'")
					gnuplot_file.close
					system("gnuplot " << File.expand_path("year_#{year_s}.gp", @tmp_path))
					
					years_total[year_s] = ::OpenStruct.new({
						year: year_s,
						revenue: revenue_year.round(NUMBER_ROUND),
						expense: expense_year.round(NUMBER_ROUND),
						balance: balance_year.round(NUMBER_ROUND),
					})
				end
				
				years_total.sort.inject(0.0){ |sum, item| item[1].balance_total = (sum + item[1].balance).round(NUMBER_ROUND) }
				
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
							<td class="right">' + ::TheFox::Wallet::NUMBER_FORMAT % year_data.revenue + '</td>
							<td class="right red">' + ::TheFox::Wallet::NUMBER_FORMAT % year_data.expense + '</td>
							<td class="right ' + (year_data.balance < 0 ? 'red' : '') + '">' + ::TheFox::Wallet::NUMBER_FORMAT % year_data.balance + '</td>
							<td class="right ' + (year_data.balance_total < 0 ? 'red' : '') + '">' + ::TheFox::Wallet::NUMBER_FORMAT % year_data.balance_total + '</td>
						</tr>')
				end
				
				balance_total = years_total.inject(0.0){ |sum, item| sum + item[1].balance }
				
				index_file.write('
						<tr>
							<th class="left"><b>TOTAL</b></th>
							<th class="right">' + ::TheFox::Wallet::NUMBER_FORMAT % years_total.inject(0.0){ |sum, item| sum + item[1].revenue } + '</th>
							<th class="right red">' + ::TheFox::Wallet::NUMBER_FORMAT % years_total.inject(0.0){ |sum, item| sum + item[1].expense } + '</th>
							<th class="right ' + (balance_total < 0 ? 'red' : '') + '">' + ::TheFox::Wallet::NUMBER_FORMAT % balance_total + '</th>
							<th>&nbsp;</th>
						</tr>
					</table>
					
					<p><img src="total.png"></p>
				')
				index_file.write('
						</body>
					</html>
				')
				index_file.close
				
				store = YAML::Store.new(html_options_path)
				store.transaction do
					store['meta'] = html_options['meta']
					store['changes'] = html_options['changes']
				end
				
				totaldat_file_c = years_total.map{ |k, y| "#{y.year} #{y.revenue} #{y.expense} #{y.balance} #{y.balance_total}" }
				if totaldat_file_c.count > 6
					totaldat_file_c = totaldat_file_c.slice(-6, 6)
				end
				totaldat_file_c = totaldat_file_c.join("\n")
				
				totaldat_file_path = File.expand_path('total.dat', @tmp_path)
				totaldat_file = File.new(totaldat_file_path, 'w')
				totaldat_file.write(totaldat_file_c)
				totaldat_file.close
				
				gnuplot_file = File.new(File.expand_path('total.gp', @tmp_path), 'w')
				gnuplot_file.puts("set title 'Total'")
				gnuplot_file.puts("set xlabel 'Years'")
				gnuplot_file.puts("set ylabel 'Euro'")
				gnuplot_file.puts("set grid")
				gnuplot_file.puts("set key below center horizontal noreverse enhanced autotitle box dashtype solid")
				gnuplot_file.puts("set tics out nomirror")
				gnuplot_file.puts("set border 3 front linetype black linewidth 1.0 dashtype solid")
				gnuplot_file.puts("set xtics 1")
				gnuplot_file.puts("set style line 1 linecolor rgb '#00ff00' linewidth 2 linetype 1 pointtype 2")
				gnuplot_file.puts("set style line 2 linecolor rgb '#ff0000' linewidth 2 linetype 1 pointtype 2")
				gnuplot_file.puts("set style line 3 linecolor rgb '#000000' linewidth 2 linetype 1 pointtype 2")
				gnuplot_file.puts("set style line 4 linecolor rgb '#0000ff' linewidth 2 linetype 1 pointtype 2")
				gnuplot_file.puts("set style data linespoints")
				gnuplot_file.puts("set terminal png enhanced")
				gnuplot_file.puts("set output '" << File.expand_path('total.png', @html_path) << "'")
				gnuplot_file.puts("plot sum = 0, \\")
				gnuplot_file.puts("\t'#{totaldat_file_path}' using 1:2 linestyle 1 title 'Revenue', \\")
				gnuplot_file.puts("\t'' using 1:3 linestyle 2 title 'Expense', \\")
				gnuplot_file.puts("\t'' using 1:4 linestyle 3 title 'Balance', \\")
				gnuplot_file.puts("\t'' using 1:5 linestyle 4 title '∑ Balance'")
				gnuplot_file.close
				
				system("gnuplot " << File.expand_path('total.gp', @tmp_path))
			end
			
			def import_csv_file(file_path)
				transaction_start
				
				row_n = 0
				csv_options = {
					:col_sep => ',',
					#:row_sep => "\n",
					:headers => true,
					:return_headers => false,
					:skip_blanks => true,
					# :encoding => 'UTF-8',
				}
				CSV.foreach(file_path, csv_options) do |row|
					if @exit
						break
					end
					row_n += 1
					
					id = row.field('id')
					date = row.field('date')
					title = row.field('title')
					revenue = row.field('revenue')
					expense = row.field('expense')
					# balance = row.field('balance')
					category = row.field('category')
					comment = row.field('comment')
					
					added = add(Entry.new(id, title, date, revenue, expense, category, comment), true)
					
					puts "import row '#{id}' -- #{added ? 'YES' : 'NO'}"
				end
				
				puts
				puts 'save data ...'
				
				transaction_end
			end
			
			def export_csv_file(file_path)
				csv_options = {
					:col_sep => ',',
					:row_sep => "\n",
					:headers => [
						'id', 'date', 'title', 'revenue', 'expense', 'balance', 'category', 'comment',
					],
					:write_headers => true,
					# :encoding => 'ISO-8859-1',
				}
				CSV.open(file_path, 'wb', csv_options) do |csv|
					Dir[File.expand_path('month_*.yml', @data_path)].each do |yaml_file_path|
						puts 'export ' + File.basename(yaml_file_path)
						
						data = YAML.load_file(yaml_file_path)
						
						data['days'].each do |day_name, day_items|
							day_items.each do |entry|
								csv << [
									entry['id'],
									entry['date'],
									entry['title'],
									::TheFox::Wallet::NUMBER_FORMAT % entry['revenue'],
									::TheFox::Wallet::NUMBER_FORMAT % entry['expense'],
									::TheFox::Wallet::NUMBER_FORMAT % entry['balance'],
									entry['category'],
									entry['comment'],
								]
							end
						end
					end
				end
			end
			
			def entry_exist?(entry)
				if !entry.is_a?(Entry)
					raise ArgumentError, 'variable must be a Entry instance'
				end
				
				!find_entry_by_id(entry.id).nil?
			end
			
			def build_entry_by_id_index(force = false)
				if @entries_by_ids.nil? || force
					@logger.debug('build entry-by-id index') if @logger
					
					glob = File.expand_path('month_*.yml', @data_path)
					
					@entries_by_ids = Dir[glob].map { |file_path|
						data = YAML.load_file(file_path)
						data['days'].map{ |day_name, day_items|
							day_items.map{ |entry|
								Entry.from_h(entry)
							}
						}
					}.flatten.map{ |entry|
						[entry.id, entry]
					}.to_h
					
					# pp @entries_by_ids
				end
			end
			
			def find_entry_by_id(id)
				build_entry_by_id_index
				
				@entries_by_ids[id]
			end
			
			private
			
			def create_dirs
				if !Dir.exist?(@dir_path)
					Dir.mkdir(@dir_path)
				end
				
				if !Dir.exist?(@data_path)
					Dir.mkdir(@data_path)
				end
				
				if !Dir.exist?(@tmp_path)
					Dir.mkdir(@tmp_path)
				end
				
				tmp_gitignore_path = File.expand_path('.gitignore', @tmp_path)
				if !File.exist?(tmp_gitignore_path)
					gitignore_file = File.open(tmp_gitignore_path, 'w')
					gitignore_file.write('*')
					gitignore_file.close
				end
			end
			
			def calc_day(day, category = nil)
				revenue = 0
				expense = 0
				balance = 0
				if category
					category.to_s.downcase!
					
					day.each do |entry|
						if entry['category'] == category
							revenue += entry['revenue']
							expense += entry['expense']
							balance += entry['balance']
						end
					end
				else
					day.each do |entry|
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
				Dir[File.expand_path('month_*.yml', @data_path)].map{ |file_path| File.basename(file_path)[6, 4].to_i }.uniq
			end
			
		end
		
	end
end
