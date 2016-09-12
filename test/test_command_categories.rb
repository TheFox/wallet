#!/usr/bin/env ruby

require 'minitest/autorun'
require 'fileutils'
require 'wallet'


class TestCategoriesCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_command
		wallet = Wallet.new('wallet_test')
		wallet.add(Entry.new(nil, 'test', '2014-01-01', 100, nil, 'category1'))
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 100, nil, 'category2'))
		
		options = {
			:wallet_path => 'wallet_test',
		}
		cmd = CategoriesCommand.new(options)
		cmd.run
	end
	
	def teardown
		FileUtils.rm_r('wallet_test', {:force => true})
	end
	
end
