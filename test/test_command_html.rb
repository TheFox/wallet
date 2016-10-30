#!/usr/bin/env ruby

require 'minitest/autorun'
require 'pathname'
require 'wallet'

class TestHtmlCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_command
		wallet_path = Pathname.new('wallet_test')
		
		wallet = Wallet.new(wallet_path)
		wallet.add(Entry.new(nil, 'test', '2014-01-01', 100))
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 50))
		wallet.add(Entry.new(nil, 'test', '2016-01-01', 50))
		
		cmd = HtmlCommand.new({:wallet_path => wallet_path})
		cmd.run
	end
	
	def teardown
		Pathname.new('wallet_test').rmtree
	end
	
end
