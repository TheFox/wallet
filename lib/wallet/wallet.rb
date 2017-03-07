
# Main Class

require 'logger'
require 'yaml'
require 'yaml/store'
require 'csv'
require 'pathname'
require 'fileutils'

# OpenStruct use to generate HTML.
require 'ostruct'

module TheFox
	module Wallet
		
		class Wallet
			
			attr_writer :logger
			attr_reader :dir_path
			
			def initialize(dir_path = nil)
				@exit = false
				@logger = nil
				@dir_path = dir_path || Pathname.new('wallet').expand_path
				@dir_path_basename = @dir_path.basename
				@dir_path_basename_s = @dir_path_basename.to_s
				@data_path = Pathname.new('data').expand_path(@dir_path)
				@tmp_path = Pathname.new('tmp').expand_path(@dir_path)
				@html_path = Pathname.new('html').expand_path(@dir_path)
				
				@has_transaction = false
				@transaction_files = Hash.new
				
				@entries_by_ids = nil
				@entries_index_file_path = Pathname.new('index.yml').expand_path(@data_path)
				@entries_index = Array.new
				@entries_index_is_loaded = false
				
				Signal.trap('SIGINT') do
					#@logger.warn('received SIGINT. break ...') if @logger
					@exit = true
				end
			end
			
			# Used by Add Command.
			def add(entry, is_unique = false)
				if !entry.is_a?(Entry)
					raise ArgumentError, 'variable must be a Entry instance'
				end
				
				if is_unique && entry_exist?(entry)
					return false
				end
				
				create_dirs
				
				date = entry.date
				date_s = date.to_s
				dbfile_basename_s = "month_#{date.strftime('%Y_%m')}.yml"
				dbfile_basename_p = Pathname.new(dbfile_basename_s)
				dbfile_path = dbfile_basename_p.expand_path(@data_path)
				tmpfile_path = Pathname.new("#{dbfile_path}.tmp")
				file = {
					'meta' => {
						'version' => 1,
						'created_at' => DateTime.now.to_s,
						'updated_at' => DateTime.now.to_s,
					},
					'days' => Hash.new,
				}
				
				@entries_index << entry.id
				
				if @has_transaction
					if @transaction_files[dbfile_basename_s]
						file = @transaction_files[dbfile_basename_s]['file']
					else
						if dbfile_path.exist?
							file = YAML.load_file(dbfile_path)
							file['meta']['updated_at'] = DateTime.now.to_s
						end
						
						@transaction_files[dbfile_basename_s] = {
							'basename' => dbfile_basename_s,
							'path' => dbfile_path.to_s,
							'tmp_path' => tmpfile_path.to_s,
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
					
					@transaction_files[dbfile_basename_s]['file'] = file
				else
					if dbfile_path.exist?
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
					
					save_entries_index_file
					
					if tmpfile_path.exist?
						tmpfile_path.rename(dbfile_path)
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
				
				save_entries_index_file
				
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
					glob << '*.yml'
				elsif year && month == nil
					glob << "#{year_s}_*.yml"
				elsif year && month
					glob << "#{year_s}_#{month_f}.yml"
				end
				
				Dir[glob].each do |file_path|
					data = YAML.load_file(file_path)
					
					if day
						day_key = "#{year_s}-#{month_f}-#{day_f}"
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
					raise RuntimeError, "diff between revenue and expense to balance is #{diff}"
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
			
			# Used by List Command.
			def entries(begin_date, category = nil)
				begin_year, begin_month, begin_day = begin_date.split('-') #.map{ |n| n.to_i }
				
				if begin_year.length > 4
					# When begin_date got not splitted by '-'.
					# YYYYM[MD[D]]
					
					begin_month = begin_year[4..-1]
					begin_year = begin_year[0..3]
					
					if begin_month.length > 2
						# YYYYMMD[D]
						
						begin_day = begin_month[2..-1]
						begin_month = begin_month[0..1]
					end
				end
				
				begin_year_s = begin_year.to_i.to_s
				begin_month_f = '%02d' % begin_month.to_i
				begin_day_f = '%02d' % begin_day.to_i
				
				glob = File.expand_path('month_', @data_path)
				if begin_year == nil && begin_month == nil
					glob << '*.yml'
				elsif begin_year && begin_month == nil
					glob << "#{begin_year_s}_*.yml"
				elsif begin_year && begin_month
					glob << "#{begin_year_s}_#{begin_month_f}.yml"
				end
				
				category = category.to_s.downcase
				
				entries_a = Hash.new
				Dir[glob].each do |file_path|
					
					data = YAML.load_file(file_path)
					if category.length == 0
						if begin_day
							day_key = "#{begin_year_s}-#{begin_month_f}-#{begin_day_f}"
							if data['days'].has_key?(day_key)
								entries_a[day_key] = data['days'][day_key]
							end
						else
							entries_a.merge!(data['days'])
						end
					else
						if begin_day
							day_key = "#{begin_year_s}-#{begin_month_f}-#{begin_day_f}"
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
			
			# Used by Categories Command.
			def categories
				categories_h = Hash.new
				Dir[Pathname.new('month_*.yml').expand_path(@data_path)].each do |file_path|
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
			
			# Used by HTML Command.
			# Generate HTML files from date_start to date_end.
			def generate_html(html_path = nil, date_start = nil, date_end = nil, category = nil)
				# @FIXME use @exit on all loops in this function
				
				html_path ||= @html_path
				
				@logger.info("generate html to #{html_path} ...") if @logger
				
				create_dirs
				
				unless html_path.exist?
					html_path.mkpath
				end
				
				html_options_path = Pathname.new('options.yml').expand_path(html_path)
				html_options = {
					'meta' => {
						'version' => 1,
						'created_at' => DateTime.now.to_s,
						'updated_at' => DateTime.now.to_s,
					},
					'changes' => Hash.new,
				}
				if html_path.exist?
					if html_options_path.exist?
						html_options = YAML.load_file(html_options_path)
						html_options['meta']['updated_at'] = DateTime.now.to_s
					end
				else
					html_path.mkpath
				end
				
				categories_available = categories
				if category
					filter_categories = category.split(',')
					categories_available &= filter_categories
				end
				
				categories_total_balance = Hash.new
				categories_available.map{ |item| categories_total_balance[item] = 0.0 }
				
				# Ignore the html directory.
				gitignore_file_path = Pathname.new('.gitignore').expand_path(html_path)
				gitignore_file = File.open(gitignore_file_path, 'w')
				gitignore_file.write('*')
				gitignore_file.close
				
				css_file_path = Pathname.new('style.css').expand_path(html_path)
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
				
				# Use this for index.html.
				years_total = Hash.new
				
				# Iterate over all years.
				years(date_start, date_end).each do |year|
					year_s = year.to_s
					year_file_name_s = "year_#{year}.html"
					year_file_name_p = Pathname.new(year_file_name_s)
					year_file_path = year_file_name_p.expand_path(html_path)
					
					year_file = File.open(year_file_path, 'w')
					year_file.write('
						<html>
							<head>
								<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
								<title>' << year_s << ' - ' << @dir_path_basename_s << '</title>
								<link rel="stylesheet" href="style.css" type="text/css" />
							</head>
							<body>
								<h1><a href="index.html">' << @dir_path_basename_s << '</a></h1>
								<p>Generated @ ' << DateTime.now.strftime('%Y-%m-%d %H:%M:%S') << ' by <a href="' << HOMEPAGE << '">' << NAME << '</a> v' << VERSION << '</p>
								
								<h2>Year: ' << year_s << '</h2>
								<table class="list">
									<tr>
										<th class="left">Month</th>
										<th class="right">Revenue</th>
										<th class="right">Expense</th>
										<th class="right">Balance</th>
										<th colspan="' << categories_available.count.to_s << '">' << categories_available.count.to_s << ' Categories</th>
									</tr>
									<tr>
										<th colspan="4">&nbsp;</th>
					')
					categories_available.each do |category|
						year_file.write(%(<th class="right">#{category}</th>))
					end
					year_file.write('</tr>')
					
					revenue_year = 0.0
					expense_year = 0.0
					balance_year = 0.0
					categories_year_balance = Hash.new
					categories_available.map{ |item| categories_year_balance[item] = 0.0 }
					year_total = Hash.new
					
					@logger.info("generate year #{year}") if @logger
					@data_path.each_child do |file_path|
						file_name_p = file_path.basename
						file_name_s = file_name_p.to_s
						
						if file_path.extname != '.yml' || Regexp.new("^month_#{year}_").match(file_name_s).nil?
							next
						end
						
						month_n = file_name_s[11, 2]
						month_file_name_s = "month_#{year}_#{month_n}.html"
						month_file_name_p = Pathname.new(month_file_name_s)
						month_file_path = month_file_name_p.expand_path(html_path)
						
						month_s = Date.parse("2015-#{month_n}-15").strftime('%B')
						
						if date_start && date_end
							file_date_start = Date.parse("#{year}-#{month_n}-01")
							file_date_end = Date.parse("#{year}-#{month_n}-01").next_month.prev_day
							
							if date_end < file_date_start ||
								date_start > file_date_end
								next
							end
						end
						
						revenue_month = 0.0
						expense_month = 0.0
						balance_month = 0.0
						categories_month_balance = Hash.new
						categories_available.map{ |item| categories_month_balance[item] = 0.0 }
						
						entry_n = 0
						data = YAML.load_file(file_path)
						
						# Determine if the html file should be updated.
						write_html = false
						if html_options['changes'][file_name_s]
							if html_options['changes'][file_name_s]['updated_at'] != data['meta']['updated_at']
								html_options['changes'][file_name_s]['updated_at'] = data['meta']['updated_at']
								write_html = true
							end
						else
							html_options['changes'][file_name_s] = {
								'updated_at' => data['meta']['updated_at'],
							}
							write_html = true
						end
						unless month_file_path.exist?
							write_html = true
						end
						
						if write_html
							@logger.debug("file: #{month_file_name_s} (from #{file_name_s})") if @logger
							
							month_file = File.open(month_file_path, 'w')
							month_file.write('
								<html>
									<head>
										<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
										<title>' << month_s << ' ' << year_s << ' - ' << @dir_path_basename_s << '</title>
										<link rel="stylesheet" href="style.css" type="text/css" />
									</head>
									<body>
										<h1><a href="index.html">' << @dir_path_basename_s << '</a></h1>
										<p>Generated @ ' << DateTime.now.strftime('%Y-%m-%d %H:%M:%S') << ' by  <a href="' << HOMEPAGE << '">' << NAME << '</a> v' << VERSION << ' from <code>' << file_name_s << '</code></p>
										
										<h2>Month: ' << month_s << ' <a href="' << year_file_name_s << '">' << year_s << '</a></h2>
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
							day_items.each do |entry|
								entry_date = Date.parse(entry['date'])
								entry_date_s = entry_date.strftime('%d.%m.%y')
								
								if category && !categories_available.include?(entry['category'])
									next
								end
								
								entry_n += 1
								revenue_month += entry['revenue']
								expense_month += entry['expense']
								balance_month += entry['balance']
								
								categories_year_balance[entry['category']] += entry['balance']
								categories_month_balance[entry['category']] += entry['balance']
								
								revenue_out = entry['revenue'] > 0 ? NUMBER_FORMAT % entry['revenue'] : '&nbsp;'
								expense_out = entry['expense'] < 0 ? NUMBER_FORMAT % entry['expense'] : '&nbsp;'
								category_out = entry['category'] == 'default' ? '&nbsp;' : entry['category']
								comment_out = entry['comment'] == '' ? '&nbsp;' : entry['comment']
								
								if write_html
									month_file.write('
										<tr>
											<td valign="top" class="left">' << entry_n.to_s << '</td>
											<td valign="top" class="left">' << entry_date_s << '</td>
											<td valign="top" class="left">' << entry['title'][0, 50] << '</td>
											<td valign="top" class="right">' << revenue_out << '</td>
											<td valign="top" class="right red">' << expense_out << '</td>
											<td valign="top" class="right ' << (entry['balance'] < 0 ? 'red' : '') << '">' << NUMBER_FORMAT % entry['balance'] << '</td>
											<td valign="top" class="right">' << category_out << '</td>
											<td valign="top" class="left">' << comment_out << '</td>
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
						if write_html
							month_file.write('
									<tr>
										<th>&nbsp;</th>
										<th>&nbsp;</th>
										<th class="left"><b>TOTAL</b></th>
										<th class="right">' << NUMBER_FORMAT % revenue_month << '</th>
										<th class="right red">' << NUMBER_FORMAT % expense_month << '</th>
										<th class="right ' << balance_class << '">' << NUMBER_FORMAT % balance_month << '</th>
										<th>&nbsp;</th>
										<th>&nbsp;</th>
									</tr>
								</table>')
							month_file.write('</body></html>')
							month_file.close
						end
						
						year_file.write('
							<tr>
								<td class="left"><a href="' << month_file_name_s << '">' << month_s << '</a></td>
								<td class="right">' << NUMBER_FORMAT % revenue_month << '</td>
								<td class="right red">' << NUMBER_FORMAT % expense_month << '</td>
								<td class="right ' << balance_class << '">' << NUMBER_FORMAT % balance_month << '</td>')
						categories_available.each do |category|
							category_balance = categories_month_balance[category]
							year_file.write('<td class="right ' << (category_balance < 0 ? 'red' : '') << '">' << NUMBER_FORMAT % category_balance << '</td>')
						end
						year_file.write('</tr>')
					end
					
					year_total.sort.inject(0.0){ |sum, item| item[1].balance_total = (sum + item[1].balance).round(NUMBER_ROUND) }
					
					year_file.write('
							<tr>
								<th class="left"><b>TOTAL</b></th>
								<th class="right">' << NUMBER_FORMAT % revenue_year << '</th>
								<th class="right red">' << NUMBER_FORMAT % expense_year << '</th>
								<th class="right ' << (balance_year < 0 ? 'red' : '') << '">' << NUMBER_FORMAT % balance_year << '</th>')
					categories_available.each do |category|
						category_balance = categories_year_balance[category]
						year_file.write('<td class="right ' << (category_balance < 0 ? 'red' : '') << '">' << NUMBER_FORMAT % category_balance << '</td>')
					end
					
					year_file.write('
							</tr>
						</table>
					')
					
					year_file.write(%{<p><img src="year_#{year_s}.png"></p>})
					year_file.write('</body></html>')
					year_file.close
					
					yeardat_file_path = Pathname.new("year_#{year_s}.dat").expand_path(@tmp_path)
					yeardat_file = File.new(yeardat_file_path, 'w')
					yeardat_file.write(year_total
						.map{ |k, m| "#{year_s}-#{m.month_s} #{m.revenue} #{m.expense} #{m.balance} #{m.balance_total} #{m.balance_total}" }
						.join("\n"))
					yeardat_file.close
					
					gnuplot_file_path = Pathname.new("year_#{year_s}.gp").expand_path(@tmp_path)
					gnuplot_file = File.new(gnuplot_file_path, 'w')
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
					gnuplot_file.puts("set output '" << File.expand_path("year_#{year_s}.png", html_path) << "'")
					gnuplot_file.puts("plot sum = 0, \\")
					gnuplot_file.puts("\t'#{yeardat_file_path}' using 1:2 linestyle 1 title 'Revenue', \\")
					gnuplot_file.puts("\t'' using 1:3 linestyle 2 title 'Expense', \\")
					gnuplot_file.puts("\t'' using 1:4 linestyle 3 title 'Balance', \\")
					gnuplot_file.puts("\t'' using 1:5 linestyle 4 title '∑ Balance'")
					gnuplot_file.close
					system("gnuplot #{gnuplot_file_path} &> /dev/null")
					
					years_total[year_s] = ::OpenStruct.new({
						year: year_s,
						revenue: revenue_year.round(NUMBER_ROUND),
						expense: expense_year.round(NUMBER_ROUND),
						balance: balance_year.round(NUMBER_ROUND),
					})
				end
				
				years_total.sort.inject(0.0){ |sum, item| item[1].balance_total = (sum + item[1].balance).round(NUMBER_ROUND) }
				
				index_file_path = Pathname.new('index.html').expand_path(html_path)
				index_file = File.open(index_file_path, 'w')
				index_file.write('
					<html>
						<head>
							<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
							<title>' << @dir_path_basename_s << '</title>
							<link rel="stylesheet" href="style.css" type="text/css" />
						</head>
						<body>
							<h1>' << @dir_path_basename_s << '</h1>
							<p>Generated @ ' << DateTime.now.strftime('%F %T') << ' by <a href="' << HOMEPAGE << '">' << NAME << '</a> v' << VERSION << '</p>
				')
				
				# Write total to index.html file.
				index_file.write('
						<table class="list">
							<tr>
								<th class="left">Year</th>
								<th class="right">Revenue</th>
								<th class="right">Expense</th>
								<th class="right">Balance</th>
								<th class="right">Balance &#8721;</th>
							</tr>')
				
				# Write years total to index.html file.
				years_total.each do |year_name, year_data|
					index_file.write('
						<tr>
							<td class="left"><a href="year_' << year_name << '.html">' << year_name << '</a></td>
							<td class="right">' << NUMBER_FORMAT % year_data.revenue << '</td>
							<td class="right red">' << NUMBER_FORMAT % year_data.expense << '</td>
							<td class="right ' << (year_data.balance < 0 ? 'red' : '') << '">' << NUMBER_FORMAT % year_data.balance << '</td>
							<td class="right ' << (year_data.balance_total < 0 ? 'red' : '') << '">' << NUMBER_FORMAT % year_data.balance_total << '</td>
						</tr>')
				end
				
				balance_total = years_total.inject(0.0){ |sum, item| sum + item[1].balance }
				
				index_file.write('
								<tr>
									<th class="left"><b>TOTAL</b></th>
									<th class="right">' << NUMBER_FORMAT % years_total.inject(0.0){ |sum, item| sum + item[1].revenue } << '</th>
									<th class="right red">' << NUMBER_FORMAT % years_total.inject(0.0){ |sum, item| sum + item[1].expense } << '</th>
									<th class="right ' << (balance_total < 0 ? 'red' : '') << '">' << NUMBER_FORMAT % balance_total << '</th>
									<th>&nbsp;</th>
								</tr>
							</table>
					
							<p><img src="total.png"></p>
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
				if totaldat_file_c.count > 10
					totaldat_file_c = totaldat_file_c.slice(-10, 10)
				end
				totaldat_file_c = totaldat_file_c.join("\n")
				
				# DAT file for GNUPlot.
				totaldat_file_path = Pathname.new('total.dat').expand_path(@tmp_path)
				totaldat_file = File.new(totaldat_file_path, 'w')
				totaldat_file.write(totaldat_file_c)
				totaldat_file.close
				
				# Generate image with GNUPlot.
				png_file_path = Pathname.new('total.png').expand_path(html_path)
				
				gnuplot_file_path = Pathname.new('total.gp').expand_path(@tmp_path)
				gnuplot_file = File.new(gnuplot_file_path, 'w')
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
				gnuplot_file.puts("set output '#{png_file_path}'")
				gnuplot_file.puts("plot sum = 0, \\")
				gnuplot_file.puts("\t'#{totaldat_file_path}' using 1:2 linestyle 1 title 'Revenue', \\")
				gnuplot_file.puts("\t'' using 1:3 linestyle 2 title 'Expense', \\")
				gnuplot_file.puts("\t'' using 1:4 linestyle 3 title 'Balance', \\")
				gnuplot_file.puts("\t'' using 1:5 linestyle 4 title '∑ Balance'")
				gnuplot_file.close
				
				system("gnuplot #{gnuplot_file_path} &> /dev/null")
				
				@logger.info('generate html done') if @logger
			end
			
			# Used by CSV Command.
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
					
					@logger.debug("import row '#{id}' -- #{added ? 'YES' : 'NO'}") if @logger
				end
				
				@logger.info('save data ...') if @logger
				
				transaction_end
			end
			
			# Used by CSV Command.
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
					Dir[Pathname.new('month_*.yml').expand_path(@data_path)].each do |yaml_file_path|
						@logger.info("export #{File.basename(yaml_file_path)}") if @logger
						
						data = YAML.load_file(yaml_file_path)
						
						data['days'].each do |day_name, day_items|
							day_items.each do |entry|
								csv << [
									entry['id'],
									entry['date'],
									entry['title'],
									NUMBER_FORMAT % entry['revenue'],
									NUMBER_FORMAT % entry['expense'],
									NUMBER_FORMAT % entry['balance'],
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
					raise ArgumentError, 'variable must be an Entry instance'
				end
				
				if @entries_index.count == 0
					load_entries_index_file
				end
				@entries_index.include?(entry.id)
			end
			
			def build_entry_by_id_index(force = false)
				if @entries_by_ids.nil? || force
					@logger.debug('build entry-by-id index') if @logger
					
					glob = Pathname.new('month_*.yml').expand_path(@data_path)
					
					@entries_by_ids = Dir[glob.to_s].map { |file_path|
						data = YAML.load_file(file_path)
						data['days'].map{ |day_name, day_items|
							day_items.map{ |entry|
								Entry.from_h(entry)
							}
						}
					}.flatten.map{ |entry|
						[entry.id, entry]
					}.to_h
				end
			end
			
			def find_entry_by_id(id)
				build_entry_by_id_index
				
				@entries_by_ids[id]
			end
			
			# Used by Clear Command.
			def clear
				c = 0
				
				# Take the standard html path instead of --path option.
				# Do not provide the functionality to delete files from --path.
				# If a user uses --path to generate html files outside of the
				# wallet path the user needs to manual remove these files.
				children = @tmp_path.children + @html_path.children
				
				children.each do |child|
					
					if child.basename.to_s[0] == '.'
						# Ignore 'hidden' files like .gitignore.
						next
					end
					
					# puts "child #{child}"
					FileUtils.rm_rf(child)
					
					c += 1
					if c > 100
						# If something goes wrong do not delete to whole harddisk. ;)
						break
					end
				end
			end
			
			private
			
			def create_dirs
				unless @dir_path.exist?
					@dir_path.mkpath
				end
				
				unless @data_path.exist?
					@data_path.mkpath
				end
				
				unless @tmp_path.exist?
					@tmp_path.mkpath
				end
				
				tmp_gitignore_path = Pathname.new('.gitignore').expand_path(@tmp_path)
				unless tmp_gitignore_path.exist?
					gitignore_file = File.open(tmp_gitignore_path, 'w')
					gitignore_file.write('*')
					gitignore_file.close
				end
				
				if @entries_index_file_path.exist?
					load_entries_index_file
				else
					build_entry_by_id_index(true)
					@entries_index = @entries_by_ids.keys
					save_entries_index_file
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
			
			def years(date_start = nil, date_end = nil)
				
				files = Array.new
				@data_path.each_child(false) do |file|
					if file.extname == '.yml' && /^month_/.match(file.to_s)
						files << file
					end
				end
				
				date_start_year = 0
				date_start_year = date_start.year if date_start
				
				date_end_year = 9999
				date_end_year = date_end.year if date_end
				
				files
					.map{ |file| file.to_s[6, 4].to_i }
					.uniq
					.keep_if{ |year| year >= date_start_year && year <= date_end_year }
			end
			
			def load_entries_index_file
				unless @entries_index_is_loaded
					@entries_index_is_loaded = true
					if @entries_index_file_path.exist?
						data = YAML.load_file(@entries_index_file_path.to_s)
						@entries_index = data['index']
					end
				end
			end
			
			def save_entries_index_file
				store = YAML::Store.new(@entries_index_file_path.to_s)
				store.transaction do
					store['index'] = @entries_index
				end
			end
			
		end
		
	end
end
