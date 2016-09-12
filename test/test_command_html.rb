#!/usr/bin/env ruby

require 'minitest/autorun'
require 'fileutils'
require 'wallet'


class TestHtmlCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_command
		wallet = Wallet.new('wallet_test')
		wallet.add(Entry.new(nil, 'test', '2014-01-01', 100))
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 50))
		wallet.add(Entry.new(nil, 'test', '2016-01-01', 50))
		
		cmd = HtmlCommand.new({:wallet_path => 'wallet_test'})
		cmd.run
	end
	
	def teardown
		FileUtils.rm_r('wallet_test', {:force => true})
	end
	
end
