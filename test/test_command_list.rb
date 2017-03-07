#!/usr/bin/env ruby

# Test List Command

require 'minitest/autorun'
require 'pathname'
require 'wallet'

class TestListCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_command
		wallet_path = Pathname.new('wallet_test')
		wallet = Wallet.new(wallet_path)
		
		# Add test data.
		wallet.add(Entry.new(nil, 'test', '2014-01-01', 100))
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 100))
		wallet.add(Entry.new(nil, 'test', '2016-01-01', 100))
		
		options = {
			:wallet_path => wallet_path,
			:entry_date => '2015-01-01',
			:entry_category => 'default',
		}
		cmd = ListCommand.new(options)
		cmd.run
	end
	
	# Clean up.
	def teardown
		Pathname.new('wallet_test').rmtree
	end
	
end
