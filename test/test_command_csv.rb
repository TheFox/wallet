#!/usr/bin/env ruby

require 'minitest/autorun'
require 'fileutils'
require 'wallet'


class TestCsvCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_command
		wallet = Wallet.new('wallet_test1')
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 100))
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 50))
		wallet.add(Entry.new(nil, 'test', '2016-01-01', 50))
		
		options = {
			:wallet_path => 'wallet_test1',
			:path => 'test.csv',
			:is_import => false,
			:is_export => true,
		}
		cmd = CsvCommand.new(options)
		cmd.run
		
		options = {
			:wallet_path => 'wallet_test2',
			:path => 'test.csv',
			:is_import => true,
			:is_export => false,
		}
		cmd = CsvCommand.new(options)
		cmd.run
		
		wallet = Wallet.new('wallet_test2')
		entries = wallet.entries('2015-01-01')
		
		assert_equal(2, entries['2015-01-01'].count)
	end
	
	def test_command_exception
		cmd = CsvCommand.new(Hash.new)
		assert_raises(RuntimeError){ cmd.run }
	end
	
	def teardown
		FileUtils.rm_r('wallet_test1', {:force => true})
		FileUtils.rm_r('wallet_test2', {:force => true})
		FileUtils.rm('test.csv', {:force => true})
	end
	
end
