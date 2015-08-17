
# Schmeisst die Fuffies durch den Club und schreit Boah Boah!

require 'yaml'
require 'yaml/store'
require 'csv'
require 'ostruct'

module Wallet
	
	class Wallet
		
		attr_reader :html_path
		
		def initialize(dir_path = 'wallet')
			@exit = false
			@dir_path = dir_path
			@data_path = File.expand_path('data', @dir_path)
			@html_path = File.expand_path('html', @dir_path)
			@tmp_path = File.expand_path('tmp', @dir_path)
			
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
			gitignore_file.write('*')
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
					
					revenue_month_r = revenue_month.round(3)
					expense_month_r = expense_month.round(3)
					balance_month_r = balance_month.round(3)
					
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
				
				year_total.sort.inject(0.0){ |sum, item| item[1].balance_total = (sum + item[1].balance).round(3) }
				
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
				
				year_file.write("<p><img src=\"year_#{year_s}.png\"></p>")
				year_file.write('</body></html>')
				year_file.close
				
				yeardat_file_path = "#{@tmp_path}/year_#{year_s}.dat"
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
				
				gnuplot_file = File.new("#{@tmp_path}/year_#{year_s}.gp", 'w')
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
				gnuplot_file.puts("set output '#{@html_path}/year_#{year_s}.png'")
				gnuplot_file.puts("plot sum = 0, \\")
				gnuplot_file.puts("\t'#{yeardat_file_path}' using 1:2 linestyle 1 title 'Revenue', \\")
				gnuplot_file.puts("\t'' using 1:3 linestyle 2 title 'Expense', \\")
				gnuplot_file.puts("\t'' using 1:4 linestyle 3 title 'Balance', \\")
				gnuplot_file.puts("\t'' using 1:5 linestyle 4 title '∑ Balance'")
				gnuplot_file.close
				system("gnuplot #{@tmp_path}/year_#{year_s}.gp")
				
				years_total[year_s] = ::OpenStruct.new({
					year: year_s,
					revenue: revenue_year.round(3),
					expense: expense_year.round(3),
					balance: balance_year.round(3),
				})
			end
			
			years_total.sort.inject(0.0){ |sum, item| item[1].balance_total = (sum + item[1].balance).round(3) }
			
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
				
				<p><img src="total.png"></p>
			')
			index_file.write('
					</body>
				</html>
			')
			index_file.close
			
			totaldat_file_c = years_total.map{ |k, y| "#{y.year} #{y.revenue} #{y.expense} #{y.balance} #{y.balance_total}" }
			totaldat_file_c = totaldat_file_c.slice(-6, 6) if totaldat_file_c.count > 6
			totaldat_file_c = totaldat_file_c.join("\n")
			
			totaldat_file_path = "#{@tmp_path}/total.dat"
			totaldat_file = File.new(totaldat_file_path, 'w')
			totaldat_file.write(totaldat_file_c)
			totaldat_file.close
			
			gnuplot_file = File.new("#{@tmp_path}/total.gp", 'w')
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
			gnuplot_file.puts("set output '#{@html_path}/total.png'")
			gnuplot_file.puts("plot sum = 0, \\")
			gnuplot_file.puts("\t'#{totaldat_file_path}' using 1:2 linestyle 1 title 'Revenue', \\")
			gnuplot_file.puts("\t'' using 1:3 linestyle 2 title 'Expense', \\")
			gnuplot_file.puts("\t'' using 1:4 linestyle 3 title 'Balance', \\")
			gnuplot_file.puts("\t'' using 1:5 linestyle 4 title '∑ Balance'")
			gnuplot_file.close
			system("gnuplot #{@tmp_path}/total.gp")
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
			
			if !Dir.exist? @tmp_path
				Dir.mkdir(@tmp_path)
			end
			
			tmp_gitignore_path = @tmp_path + '/.gitignore'
			if !File.exist?(tmp_gitignore_path)
				gitignore_file = File.open(tmp_gitignore_path, 'w')
				gitignore_file.write('*')
				gitignore_file.close
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
