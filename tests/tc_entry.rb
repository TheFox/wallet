#!/usr/bin/env ruby -w

require 'bundler/setup'
require 'minitest/autorun'
require 'wallet'

class TestEntry < MiniTest::Test
	def test_base
		entry = Wallet::Entry.new
		
		assert_equal('Wallet::Entry', entry.class.to_s)
	end
	
	def test_set
		now = DateTime.now.to_date
		
		entry = Wallet::Entry.new
		assert_equal('Date', entry.date.class.to_s)
		assert_equal(now.to_s, entry.date.to_s)
		assert_equal(0, entry.amount)
		
		entry = Wallet::Entry.new('2015-02-21', 20)
		assert_equal('Date', entry.date.class.to_s)
		assert_equal('2015-02-21', entry.date.to_s)
		assert_equal(20, entry.amount)
		
		entry.date = '2015-01-01'
		entry.amount = 24
		assert_equal('2015-01-01', entry.date.to_s)
		assert_equal(24, entry.amount)
		
		entry.amount = 24.42
		assert_equal(24.42, entry.amount)
		
		entry = Wallet::Entry.new(Date.parse('2015-01-02'))
		assert_equal('2015-01-02', entry.date.to_s)
		
		entry = Wallet::Entry.new
		entry.date = DateTime.now.to_date
		assert_equal(now.to_s, entry.date.to_s)
		
		entry = Wallet::Entry.new('2015-02-21', -42)
		assert_equal(-42, entry.amount)
		
		entry = Wallet::Entry.new('2015-02-21', -42.24)
		assert_equal(-42.24, entry.amount)
		
		entry = Wallet::Entry.new('2015-02-21', 20, 'c1')
		assert_equal('c1', entry.category)
	end
	
	def test_to_hash
		entry = Wallet::Entry.new('2015-02-21', 20)
		puts entry.to_h.to_s
	end
	
	def test_exceptions
		entry = Wallet::Entry.new('2015-02-21', 20)
		
		assert_raises(ArgumentError){ entry.date = 12 }
		assert_raises(ArgumentError){ entry.amount = 'string1' }
	end
end
