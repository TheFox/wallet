
module TheFox::Wallet
	
	class HtmlCommand < Command
		
		NAME = 'html'
		
		def run
			wallet = Wallet.new(@options[:wallet_path])
			wallet.logger = @options[:logger]
			
			html_path = Pathname.new('html').expand_path(wallet.dir_path)
			if @options[:path]
				html_path = Pathname.new(@options[:path]).expand_path
			end
			
			@options[:logger].info("generate html to #{html_path} ...") if @options[:logger]
			wallet.gen_html(html_path, @options[:entry_date_start], @options[:entry_date_end], @options[:entry_category])
			@options[:logger].info('generate html done') if @options[:logger]
		end
		
	end
	
end
