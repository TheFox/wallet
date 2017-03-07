
module TheFox::Wallet
	
	# List all used categories.
	class CategoriesCommand < Command
		
		NAME = 'categories'
		
		def run
			wallet = Wallet.new(@options[:wallet_path])
			puts wallet.categories
		end
		
	end
	
end
