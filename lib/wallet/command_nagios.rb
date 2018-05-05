
require 'pp'

module TheFox::Wallet
	
	class NagiosCommand < Command
		
		NAME = 'nagios'
		
		def run
			wallet = Wallet.new(@options[:wallet_path])
			entries = wallet.entries(@options[:entry_date], @options[:entry_category].to_s)
			
			pp entries
		end
		
	end
	
end
