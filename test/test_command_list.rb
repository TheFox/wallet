#!/usr/bin/env ruby

require 'minitest/autorun'
require 'fileutils'
require 'wallet'


class TestListCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_command
		wallet = Wallet.new('wallet_test')
		wallet.add(Entry.new(nil, 'test', '2014-01-01', 100))
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 100))
		wallet.add(Entry.new(nil, 'test', '2016-01-01', 100))
		
		options = {
			:wallet_path => 'wallet_test',
			:entry_date => '2015-01-01',
			:entry_category => 'default',
		}
		cmd = ListCommand.new(options)
		cmd.run
	end
	
	def teardown
		FileUtils.rm_r('wallet_test', {:force => true})
	end
	
end
