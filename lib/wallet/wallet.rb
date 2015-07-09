
# Schmeisst die Fuffies durch den Club und schreit Boah Boah!

require 'yaml'
require 'yaml/store'
require 'csv'

module Wallet
	
	class Wallet
		
		def initialize(dir_path = 'wallet')
			@dir_path = dir_path
			@data_path = File.expand_path('data', @dir_path)
			@html_path = File.expand_path('html', @dir_path)
		end
		
		def add(entry)
			if !entry.is_a? Entry
				raise ArgumentError, 'variable must be a Entry instance'
			end
			
			create_dirs()
			
			date = entry.date
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
			
			if File.exist? dbfile_path
				file = YAML.load_file(dbfile_path)
				file['meta']['updated_at'] = DateTime.now.to_s
			end
			
			date_key = date.to_s
			if !file['days'].has_key? date_key
				file['days'][date_key] = []
			end
			
			file['days'][date_key].push entry.to_h
			
			store = YAML::Store.new tmpfile_path
			store.transaction do
				store['meta'] = file['meta']
				store['days'] = file['days']
			end
			
			if File.exist? tmpfile_path
				File.rename tmpfile_path, dbfile_path
			end
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
			
			entries_a = {}
			Dir[glob].each do |file_path|
				data = YAML.load_file(file_path)
				if category.nil?
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
				
				wallet_js_dir_path = @html_path + '/js'
				Dir.mkdir(wallet_js_dir_path)
				
				lib_base_path = File.expand_path(File.dirname(__FILE__) + '/../..')
				js_base_path = lib_base_path + '/js'
				puts 'lib_base_path: ' + lib_base_path
				puts 'js_base_path:  ' + js_base_path
				
				FileUtils.cp(['highcharts.js', 'jquery-1.8.2.js'].map{ |file_name| js_base_path + '/' + file_name }, wallet_js_dir_path)
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
				table, th, td {
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
						<script type="text/javascript" src="js/jquery-1.8.2.js"></script>
						<script type="text/javascript" src="js/highcharts.js"></script>
					</head>
					<body>
						<h1>' + @dir_path + '</h1>
						<p>Generated @ ' + DateTime.now.strftime('%Y-%m-%d %H:%M:%S') + ' by  <a href="' + ::Wallet::HOMEPAGE + '">' + ::Wallet::NAME + '</a> ' + ::Wallet::VERSION + '</p>
						
						<h2>Years</h2>
						
						<!--<table>
							<tr>
								<td>//-->
									<ul>
			')
			
			years_total = {}
			years.reverse.each do |year|
				year_s = year.to_s
				year_file_name = 'year_' + year_s + '.html'
				year_file_path = @html_path + '/' + year_file_name
				
				index_file.write('<li><a href="' + year_file_name + '">' + year_s + '</a><ul>')
				
				year_file = File.open(year_file_path, 'w')
				year_file.write('
					<html>
						<head>
							<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
							<title>' + year_s + ' - ' + @dir_path + '</title>
							<link rel="stylesheet" href="style.css" type="text/css" />
							<script type="text/javascript" src="js/jquery-1.8.2.js"></script>
							<script type="text/javascript" src="js/highcharts.js"></script>
						</head>
						<body>
							<h1><a href="index.html">' + @dir_path + '</a></h1>
							<p>Generated @ ' + DateTime.now.strftime('%Y-%m-%d %H:%M:%S') + ' by  <a href="' + ::Wallet::HOMEPAGE + '">' + ::Wallet::NAME + '</a> ' + ::Wallet::VERSION + '</p>
							
							<h2>Year: ' + year_s + '</h2>
							<table>
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
					index_file.write('<li><a href="' + month_file_name + '">' + month_s + '</a></li>')
					
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
								<table>
									<tr>
										<th class="left">Date</th>
										<th class="left first_column">Title</th>
										<th class="right">Revenue</th>
										<th class="right">Expense</th>
										<th class="right">Balance</th>
										<th class="right">Category</th>
										<th class="right">Comment</th>
									</tr>
					')
					
					revenue_month = 0.0
					expense_month = 0.0
					balance_month = 0.0
					categories_month_balance = {}
					categories_available.map{ |item| categories_month_balance[item] = 0.0 }
					
					data = YAML.load_file(file_path)
					data['days'].sort.each do |day_name, day_items|
						puts "\t\t" + 'day: ' + day_name
						day_items.each do |entry|
							revenue_month += entry['revenue']
							expense_month += entry['expense']
							balance_month += entry['balance']
							
							categories_year_balance[entry['category']] += entry['balance']
							categories_month_balance[entry['category']] += entry['balance']
							
							balance_class = ''
							if entry['balance'] < 0
								balance_class = 'red'
							end
							
							revenue_out = entry['revenue'] > 0 ? ::Wallet::NUMBER_FORMAT % entry['revenue'] : '&nbsp;'
							expense_out = entry['expense'] < 0 ? ::Wallet::NUMBER_FORMAT % entry['expense'] : '&nbsp;'
							category_out = entry['category'] == 'default' ? '&nbsp;' : entry['category']
							comment_out = entry['comment'] == '' ? '&nbsp;' : entry['comment']
							
							month_file.write('
								<tr>
									<td class="left">' + Date.parse(entry['date']).strftime('%d.%m.%y') + '</td>
									<td class="left">' + entry['title'][0, 50] + '</td>
									<td class="right">' + revenue_out + '</td>
									<td class="right red">' + expense_out + '</td>
									<td class="right ' + balance_class + '">' + ::Wallet::NUMBER_FORMAT % entry['balance'] + '</td>
									<td class="right">' + category_out + '</td>
									<td class="right">' + comment_out + '</td>
								</tr>')
						end
					end
					
					revenue_year += revenue_month
					expense_year += expense_month
					balance_year += balance_month
					year_total[month_n] = {
						'name' => month_s,
						'revenue' => revenue_month,
						'expense' => expense_month,
						'balance' => balance_month,
					}
					
					balance_class = ''
					if balance_month < 0
						balance_class = 'red'
					end
					month_file.write('
							<tr>
								<th>&nbsp;</th>
								<th class="left"><b>TOTAL</b></th>
								<th class="right">' + ::Wallet::NUMBER_FORMAT % revenue_month + '</th>
								<th class="right red">' + ::Wallet::NUMBER_FORMAT % expense_month + '</th>
								<th class="right ' + balance_class + '">' + ::Wallet::NUMBER_FORMAT % balance_month + '</th>
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
						balance_class = ''
						if category_balance < 0
							balance_class = 'red'
						end
						year_file.write('<td class="right ' + balance_class + '">' + ::Wallet::NUMBER_FORMAT % category_balance + '</td>')
					end
					year_file.write('</tr>')
				end
				
				index_file.write('</ul></li>')
				
				balance_class = ''
				if balance_year < 0
					balance_class = 'red'
				end
				year_file.write('
						<tr>
							<th class="left"><b>TOTAL</b></th>
							<th class="right">' + ::Wallet::NUMBER_FORMAT % revenue_year + '</th>
							<th class="right red">' + ::Wallet::NUMBER_FORMAT % expense_year + '</th>
							<th class="right ' + balance_class + '">' + ::Wallet::NUMBER_FORMAT % balance_year + '</th>')
				categories_available.each do |category|
					category_balance = categories_year_balance[category]
					balance_class = ''
					if category_balance < 0
						balance_class = 'red'
					end
					year_file.write('<td class="right ' + balance_class + '">' + ::Wallet::NUMBER_FORMAT % category_balance + '</td>')
				end
				
				year_file.write('
						</tr>
					</table>
					
					<p><div id="charts" style="width:' + (year_total.keys.count * 100).to_s + 'px; height:400px;"></div></p>
					<script type="text/javascript">
						$(function(){
							$(\'#charts\').highcharts({
								chart: { type: \'line\' },
								title: { text: \'Months\' },
								xAxis: {
									categories: [\'' + year_total.map{ |item| item[1]['name'] }.join("', '") + '\']
								},
								yAxis: { title: { text: \'Money\' } },
								tooltip: { enabled: false },
								legend: {
									layout: \'vertical\',
									align: \'right\',
									verticalAlign: \'middle\',
									borderWidth: 0,
									enabled: false
								},
								series: [
									{
										name: \'Balance\',
										data: [' + year_total.map{ |item| item[1]['balance'].round(3) }.join(', ') + ']
									}
								]
							});
						});
					</script>
				')
				year_file.write('</body></html>')
				year_file.close
				
				years_total[year_s] = {
					'revenue' => revenue_year,
					'expense' => expense_year,
					'balance' => balance_year,
				}
			end
			
			revenue_total = 0.0
			expense_total = 0.0
			balance_total = 0.0
			
			index_file.write('
					</ul>
				<!--</td>	
				<td>//-->
					<table>
						<tr>
							<th class="left">Year</th>
							<th class="right">Revenue</th>
							<th class="right">Expense</th>
							<th class="right">Balance</th>
						</tr>')
			years_total.each do |year_name, year_data|
				revenue_total += year_data['revenue']
				expense_total += year_data['expense']
				balance_total += year_data['balance']
				
				balance_class = ''
				if year_data['balance'] < 0
					balance_class = 'red'
				end
				index_file.write('
					<tr>
						<td class="left">' + year_name + '</td>
						<td class="right">' + ::Wallet::NUMBER_FORMAT % year_data['revenue'] + '</td>
						<td class="right red">' + ::Wallet::NUMBER_FORMAT % year_data['expense'] + '</td>
						<td class="right ' + balance_class + '">' + ::Wallet::NUMBER_FORMAT % year_data['balance'] + '</td>
					</tr>')
			end
			
			years_total_series_out = years_total.map{ |item| item[1]['balance'].round(3) }.take(5).reverse
			
			balance_class = ''
			if balance_total < 0
				balance_class = 'red'
			end
			index_file.write('
							<tr>
								<th class="left"><b>TOTAL</b></th>
								<th class="right">' + ::Wallet::NUMBER_FORMAT % revenue_total + '</th>
								<th class="right red">' + ::Wallet::NUMBER_FORMAT % expense_total + '</th>
								<th class="right ' + balance_class + '">' + ::Wallet::NUMBER_FORMAT % balance_total + '</th>
							</tr>
						</table>
				<!--	</tr>
				</table>//-->
				
				<p><div id="charts" style="width:' + (years_total_series_out.count * 100).to_s + 'px; height:400px;"></div></p>
				<script type="text/javascript">
					$(function(){
						$(\'#charts\').highcharts({
							chart: { type: \'line\' },
							title: { text: \'Years\' },
							xAxis: { categories: [\'' + years_total.keys.take(5).reverse.join("', '") + '\'] },
							yAxis: { title: { text: \'Money\' } },
							tooltip: { enabled: false },
							legend: { enabled: false },
							series: [
								{
									name: \'Balance\',
									data: [' + years_total_series_out.join(', ') + ']
								}
							]
						});
					});
				</script>
			')
			index_file.write('</body></html>')
			index_file.close
		end
		
		def import_csv_file(file_path)
			row_n = 0
			CSV.foreach(file_path) do |row|
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
