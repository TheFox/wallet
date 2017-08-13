#!/usr/bin/env ruby

# Test Categories Command

require 'minitest/autorun'
require 'pathname'
require 'wallet'

class TestCategoriesCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_command
		wallet_path = Pathname.new('tmp/wallet_test')
		wallet = Wallet.new(wallet_path)
		
		# Add test data.
		wallet.add(Entry.new(nil, 'test', '2014-01-01', 100, nil, 'category1'))
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 100, nil, 'category2'))
		
		options = {
			:wallet_path => wallet_path,
		}
		cmd = CategoriesCommand.new(options)
		cmd.run
	end
	
	# Clean up.
	def teardown
		Pathname.new('tmp/wallet_test').rmtree
	end
	
end
