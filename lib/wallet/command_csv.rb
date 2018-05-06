
module TheFox::Wallet
	
	# Import or export to/from CSV file format.
	class CsvCommand < Command
		
		NAME = 'csv'
		
		def run
			if @options[:path].nil?
				raise "Option --path is required for command '#{NAME}'"
			end
			
			wallet = Wallet.new(@options[:wallet_path])
			wallet.logger = @options[:logger]
			
			# Import by default.
			if @options[:is_import] || !@options[:is_export]
				# Import
				@options[:logger].info("import csv #{@options[:path]} ...") if @options[:logger]
				wallet.import_csv_file(@options[:path])
				@options[:logger].info("import csv #{@options[:path]} done") if @options[:logger]
			elsif @options[:is_export]
				# Export
				@options[:logger].info("export csv #{@options[:path]} ...") if @options[:logger]
				wallet.export_csv_file(@options[:path])
				@options[:logger].info("export csv #{@options[:path]} done") if @options[:logger]
			end
			
			0
		end
		
	end
	
end
