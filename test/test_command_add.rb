#!/usr/bin/env ruby

require 'minitest/autorun'
require 'wallet'
require 'pp'


class TestAddCommand < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_command
		options = {
			:wallet_path => 'wallet_test',
			:entry_id => 'id1',
			:entry_title => 'Test1',
			:entry_date => '2014-01-01'
		}
		cmd = AddCommand.new(options)
		cmd.run
		
		wallet = Wallet.new('wallet_test')
		entries = wallet.entries('2014-01-01')
		
		assert_equal(1, entries['2014-01-01'].count)
	end
	
	def test_command_exception
		options = {
			:wallet_path => 'wallet_test',
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
	
	def teardown
		FileUtils.rm_r('wallet_test', {:force => true})
	end
	
end
