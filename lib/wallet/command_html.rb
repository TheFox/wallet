
require 'pathname'

module TheFox::Wallet
	
	class HtmlCommand < Command
		
		NAME = 'html'
		
		def run
			if @options[:path]
				html_path = Pathname.new(@options[:path]).expand_path
			end
			
			wallet = Wallet.new(@options[:wallet_path])
			wallet.logger = @options[:logger]
			wallet.generate_html(html_path, @options[:entry_date_start], @options[:entry_date_end], @options[:entry_category])
		end
		
	end
	
end
