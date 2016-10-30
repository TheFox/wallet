
module TheFox::Wallet
	
	class HtmlCommand < Command
		
		NAME = 'html'
		
		def run
			wallet = Wallet.new(@options[:wallet_path])
			puts "generate html to #{wallet.html_path} ..."
			wallet.gen_html
			puts 'generate html done'
		end
		
	end
	
end
