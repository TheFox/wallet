#!/usr/bin/env ruby

require 'minitest/autorun'
require 'wallet'


class TestAddCommand < MiniTest::Test
	def test_revenue
		cmd = TheFox::Wallet::AddCommand.new
		
		# String
		assert_equal(0.0, cmd.revenue(nil))
		assert_equal(0.0, cmd.revenue(''))
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
		cmd = TheFox::Wallet::AddCommand.new
		
		# String
		assert_equal(0.0, cmd.expense(nil))
		assert_equal(0.0, cmd.expense(''))
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
end
