
require 'yaml'
require 'yaml/store'

module Wallet
	
	class Wallet
		
		def initialize(dir_path = 'wallet')
			@dir_path = dir_path
			@data_path = File.expand_path('data', @dir_path)
		end
		
		def add(entry)
			if !entry.is_a? Entry
				raise ArgumentError, 'variable must be a Entry instance'
			end
			
			if !Dir.exist? @dir_path
				Dir.mkdir(@dir_path)
			end
			
			if !Dir.exist? @data_path
				Dir.mkdir(@data_path)
			end
			
			date = entry.date
			dbfile_basename = 'month_' + date.strftime('%Y_%m') + '.yml'
			dbfile_path = File.expand_path(dbfile_basename, @data_path)
			tmpfile_path = dbfile_path + '.tmp'
			
			file = {
				'meta' => {
					'version' => 1,
					'created_at' => DateTime.now.to_s,
				},
				'days' => {}
			}
			
			if File.exist? dbfile_path
				file = YAML.load_file(dbfile_path)
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
		
		def balance(year = nil, month = nil, day = nil)
			puts 'year: ' + year.to_s
			puts 'month: ' + month.to_s
			puts 'day: ' + day.to_s
			
			revenue = 21
			expense = -10
			profit = revenue + expense
			
			{:revenue => revenue, :expense => expense, :profit => profit}
		end
		
	end
	
end
