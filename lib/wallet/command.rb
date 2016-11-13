
require 'date'
require 'pathname'

module TheFox::Wallet
	
	class Command
		
		NAME = 'default'
		
		def initialize(options = Hash.new)
			@options = options || Hash.new
			@options[:logger] ||= nil
			
			@options[:wallet_path] ||= Pathname.new('wallet')
			@options[:entry_id] ||= nil
			@options[:entry_title] ||= nil
			@options[:entry_date] ||= Date.today.to_s
			@options[:entry_date_start] ||= Date.parse('1970-01-01')
			@options[:entry_date_end] ||= Date.today
			@options[:entry_revenue] ||= 0.0
			@options[:entry_expense] ||= 0.0
			@options[:entry_category] ||= nil
			@options[:entry_comment] ||= nil
			@options[:is_import] ||= false
			@options[:is_export] ||= false
			@options[:path] ||= nil
			@options[:is_interactively] ||= false
			@options[:force] ||= false
		end
		
		def run
		end
		
		def self.create_by_name(name, options = nil)
			classes = [
				AddCommand,
				ListCommand,
				CategoriesCommand,
				HtmlCommand,
				CsvCommand,
			]
			
			classes.each do |cclass|
				#puts "class: '#{cclass::NAME}' '#{cclass.is_matching_class(name)}'"
				if cclass.is_matching_class(name)
					return cclass.new(options)
				end
			end
			
			raise "Unknown command '#{name}'"
		end
		
		def self.is_matching_class(name)
			name == self::NAME
		end
		
	end
	
end
