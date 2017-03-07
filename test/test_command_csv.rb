#!/usr/bin/env ruby

# Test CSV Command

require 'minitest/autorun'
require 'pathname'
require 'wallet'

class TestCsvCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_command
		wallet_path = Pathname.new('wallet_test1')
		wallet = Wallet.new(wallet_path)
		
		# Add test data.
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 100))
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 50))
		wallet.add(Entry.new(nil, 'test', '2016-01-01', 50))
		
		# Export CSV
		options = {
			:wallet_path => wallet_path,
			:path => 'test.csv',
			:is_import => false,
			:is_export => true,
		}
		cmd = CsvCommand.new(options)
		cmd.run
		
		# Import CSV
		wallet_path = Pathname.new('wallet_test2')
		options = {
			:wallet_path => wallet_path,
			:path => 'test.csv',
			:is_import => true,
			:is_export => false,
		}
		cmd = CsvCommand.new(options)
		cmd.run
		
		# The entries of the import wallet.
		wallet = Wallet.new(wallet_path)
		entries = wallet.entries('2015-01-01')
		
		assert_equal(2, entries['2015-01-01'].count)
	end
	
	def test_command_exception
		cmd = CsvCommand.new(Hash.new)
		assert_raises(RuntimeError){ cmd.run }
	end
	
	# Clean up.
	def teardown
		wallet_path = Pathname.new('wallet_test1')
		if wallet_path.exist?
			wallet_path.rmtree
		end
		
		wallet_path = Pathname.new('wallet_test2')
		if wallet_path.exist?
			wallet_path.rmtree
		end
		
		csv_file_path = Pathname.new('test.csv')
		if csv_file_path.exist?
			csv_file_path.unlink
		end
	end
	
end
