
module TheFox::Wallet
	
	class CategoriesCommand < Command
		
		NAME = 'categories'
		
		def run
			wallet = Wallet.new(@options[:wallet_path])
			categories = wallet.categories
			puts "categories: #{categories.count}"
			puts "\t" << categories.join("\n\t")
		end
		
	end
	
end
