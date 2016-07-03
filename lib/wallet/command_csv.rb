
module TheFox::Wallet
	
	class CsvCommand < Command
		
		NAME = 'csv'
		
		def run
			if @options[:is_interactively]
				vi_file = Tempfile.create('wallet-vi-import', '/tmp')
				vi_file.puts('# This is a comment line.')
				vi_file.puts('# Date,Title,Revenue,Expense,Category,Comment')
				vi_file.puts('# Date,Title,Expense')
				vi_file.puts
				vi_file.puts
				vi_file.close
				
				puts 'cwd:    ' + Dir.pwd
				puts 'editor: ' + ENV['EDITOR']
				puts 'file:   ' + vi_file.path
				
				system("#{ENV['EDITOR']} #{vi_file.path}")
				system("grep -v '#' #{vi_file.path} | grep -v ^$ > #{vi_file.path}.ok")
				
				@options[:path] = "#{vi_file.path}.ok"
				File.unlink(vi_file.path)
			end
			
			if @options[:path].nil?
				raise "Option --path is required for command '#{NAME}'"
			end
			
			wallet = Wallet.new(@options[:wallet_path])
			
			if @options[:is_import] || !@options[:is_export]
				puts "import csv #{@options[:path]} ..."
				wallet.import_csv_file(@options[:path])
				puts "import csv #{@options[:path]} done"
				
				if @options[:is_interactively]
					puts "delete #{@options[:path]}"
					File.unlink(@options[:path])
				end
			elsif @options[:is_export]
				puts "export csv #{@options[:path]} ..."
				wallet.export_csv_file(@options[:path])
				puts "export csv #{@options[:path]} done"
			end
		end
		
	end
	
end
