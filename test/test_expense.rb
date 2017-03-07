#!/usr/bin/env ruby

# Test Expense

require 'minitest/autorun'
require 'wallet'

class TestExpense < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_addition
		n = Expense.new(7) + Expense.new(3)
		puts "n #{n}"
		#assert_equal(10, n)
	end
	
end
