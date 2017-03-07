#!/usr/bin/env ruby

# Test Add Command

require 'minitest/autorun'
require 'pathname'
require 'wallet'

class TestAddCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_add_command1
		options = {
			:wallet_path => Pathname.new('wallet_test'),
			:entry_title => 'Test1',
			:entry_date => '2014-01-01',
		}
		cmd = AddCommand.new(options)
		assert_equal(true, cmd.run)
		
		wallet = Wallet.new(options[:wallet_path])
		entries = wallet.entries('2014-01-01')
		assert_equal(1, entries['2014-01-01'].count)
	end
	
	def test_add_command2
		wallet_path = Pathname.new('wallet_test')
		wallet = Wallet.new(wallet_path)
		
		options = {
			:wallet_path => wallet_path,
			:entry_title => 'Test1',
			:entry_date => '2014-01-01',
			# :entry_id => ,
			# :force => ,
		}
		cmd = AddCommand.new(options)
		assert_equal(true, cmd.run)
		
		entries = wallet.entries('2014-01-01')
		assert_equal(1, entries['2014-01-01'].count)
		
		
		options = {
			:wallet_path => wallet_path,
			:entry_title => 'Test2',
			:entry_date => '2014-01-01',
			# :entry_id => ,
			# :force => ,
		}
		cmd = AddCommand.new(options)
		assert_equal(true, cmd.run)
		
		entries = wallet.entries('2014-01-01')
		assert_equal(2, entries['2014-01-01'].count)
		
		
		options = {
			:wallet_path => wallet_path,
			:entry_title => 'Test3',
			:entry_date => '2014-01-01',
			:entry_id => 'test1',
			# :force => ,
		}
		cmd = AddCommand.new(options)
		assert_equal(true, cmd.run)
		
		entries = wallet.entries('2014-01-01')
		assert_equal(3, entries['2014-01-01'].count)
		
		
		options = {
			:wallet_path => wallet_path,
			:entry_title => 'Test4',
			:entry_date => '2014-01-01',
			:entry_id => 'test1',
			# :force => ,
		}
		cmd = AddCommand.new(options)
		assert_equal(false, cmd.run)
		
		entries = wallet.entries('2014-01-01')
		assert_equal(3, entries['2014-01-01'].count)
		
		
		options = {
			:wallet_path => wallet_path,
			:entry_title => 'Test4',
			:entry_date => '2014-01-01',
			:entry_id => 'test1',
			:force => false,
		}
		cmd = AddCommand.new(options)
		assert_equal(false, cmd.run)
		
		entries = wallet.entries('2014-01-01')
		assert_equal(3, entries['2014-01-01'].count)
		
		
		options = {
			:wallet_path => wallet_path,
			:entry_title => 'Test4',
			:entry_date => '2014-01-01',
			:entry_id => 'test1',
			:force => true,
		}
		cmd = AddCommand.new(options)
		assert_equal(true, cmd.run)
		
		entries = wallet.entries('2014-01-01')
		assert_equal(4, entries['2014-01-01'].count)
		
		
		options = {
			:wallet_path => wallet_path,
			:entry_title => 'Test5',
			:entry_date => '2014-01-01',
			# :entry_id => 'test1',
			:force => false,
		}
		cmd = AddCommand.new(options)
		assert_equal(true, cmd.run)
		
		entries = wallet.entries('2014-01-01')
		assert_equal(5, entries['2014-01-01'].count)
		
		
		options = {
			:wallet_path => wallet_path,
			:entry_title => 'Test6',
			:entry_date => '2014-01-01',
			# :entry_id => 'test1',
			:force => true,
		}
		cmd = AddCommand.new(options)
		assert_equal(true, cmd.run)
		
		entries = wallet.entries('2014-01-01')
		assert_equal(6, entries['2014-01-01'].count)
	end
	
	def test_command_exception
		options = {
			:wallet_path => Pathname.new('wallet_test'),
		}
		cmd = AddCommand.new(options)
		assert_raises(RuntimeError){ cmd.run }
	end
	
	def test_revenue
		cmd = AddCommand.new
		
		# String
		assert_equal(nil, cmd.revenue(nil))
		assert_equal(nil, cmd.revenue(''))
		assert_equal(21.0, cmd.revenue('21'))
		assert_equal(21.0, cmd.revenue(' 21 '))
		
		# Negative
		assert_equal(21.0, cmd.revenue('-21'))
		
		# Float
		assert_equal(21.2, cmd.revenue('21.2'))
		assert_equal(21.2, cmd.revenue('21.20'))
		assert_equal(21.87, cmd.revenue('21.87'))
		
		# Calc
		assert_equal(16, cmd.revenue('21-5'))
		assert_equal(15.8, cmd.revenue('21.7-5.9'))
		assert_equal(14.8, cmd.revenue('22,7-7,9'))
		assert_equal(29, cmd.revenue('21-50'))
		assert_equal(0.1, cmd.revenue('0,1-0,2'))
		assert_equal(0.0, cmd.revenue('0,1-0,1'))
	end
	
	def test_expense
		cmd = AddCommand.new
		
		# String
		assert_equal(nil, cmd.expense(nil))
		assert_equal(nil, cmd.expense(''))
		assert_equal(-21.0, cmd.expense('21'))
		assert_equal(-21.0, cmd.expense(' 21 '))
		
		# Positive
		assert_equal(-21.0, cmd.expense('-21'))
		assert_equal(-21.0, cmd.expense('21'))
		
		# Float
		assert_equal(-21.2, cmd.expense('21.2'))
		assert_equal(-21.2, cmd.expense('21.20'))
		assert_equal(-21.87, cmd.expense('21.87'))
		
		# Calc
		assert_equal(-16, cmd.expense('21-5'))
		assert_equal(-15.8, cmd.expense('21.7-5.9'))
		assert_equal(-14.8, cmd.expense('22,7-7,9'))
		assert_equal(-29, cmd.expense('21-50'))
		assert_equal(-0.1, cmd.expense('0,1-0,2'))
		assert_equal(0.0, cmd.expense('0,1-0,1'))
	end
	
	# Clean up.
	def teardown
		wallet_path = Pathname.new('wallet_test')
		if wallet_path.exist?
			wallet_path.rmtree
		end
	end
	
end
