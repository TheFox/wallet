
module TheFox::Wallet
	
	class CsvCommand < Command
		
		NAME = 'csv'
		
		def run
			if @options[:path].nil?
				raise "Option --path is required for command '#{NAME}'"
			end
			
			wallet = Wallet.new(@options[:wallet_path])
			
			if @options[:is_import] || !@options[:is_export]
				puts "import csv #{@options[:path]} ..."
				wallet.import_csv_file(@options[:path])
				puts "import csv #{@options[:path]} done"
			elsif @options[:is_export]
				puts "export csv #{@options[:path]} ..."
				wallet.export_csv_file(@options[:path])
				puts "export csv #{@options[:path]} done"
			end
		end
		
	end
	
end
