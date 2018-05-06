
require 'pathname'

module TheFox::Wallet
	
	# Clear temp and cache files.
	class ClearCommand < Command
		
		NAME = 'clear'
		
		def run
			wallet = Wallet.new(@options[:wallet_path])
			wallet.logger = @options[:logger]
			wallet.clear
			
			0
		end
		
	end
end
