#!/usr/bin/env ruby

# Test Revenue

require 'minitest/autorun'
require 'wallet'

class TestRevenue < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_addition
		n = Revenue.new(7) + Revenue.new(3)
		puts "n #{n}"
		#assert_equal(10, n)
	end
	
end
