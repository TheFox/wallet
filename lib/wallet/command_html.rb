
require 'pathname'

module TheFox::Wallet
	
	# Exports a wallet as HTML.
	# List all years in an index HTML file and all months for each year.
	# Generates a HTML file for each month based on entries.
	class HtmlCommand < Command
		
		NAME = 'html'
		
		def run
			if @options[:path]
				html_path = Pathname.new(@options[:path]).expand_path
			end
			
			wallet = Wallet.new(@options[:wallet_path])
			wallet.logger = @options[:logger]
			wallet.generate_html(html_path, @options[:entry_date_start], @options[:entry_date_end], @options[:entry_category])
			
			0
		end
		
	end
	
end
