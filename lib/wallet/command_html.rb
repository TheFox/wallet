
module TheFox::Wallet
	
	class HtmlCommand < Command
		
		NAME = 'html'
		
		def run
			wallet = Wallet.new(@options[:wallet_path])
			wallet.logger = @options[:logger]
			
			@options[:logger].info("generate html to #{wallet.html_path} ...") if @options[:logger]
			wallet.gen_html
			@options[:logger].info('generate html done') if @options[:logger]
		end
		
	end
	
end
