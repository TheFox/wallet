#!/usr/bin/env ruby

# Test Wnumber

require 'minitest/autorun'
require 'wallet'

class TestWumber < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_addition
		n = Wumber.new(7) + Wumber.new(3)
		assert_equal(10, n.to_i)
	end
	
end
