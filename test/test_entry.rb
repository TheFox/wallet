#!/usr/bin/env ruby

# Test Entry

require 'minitest/autorun'
require 'wallet'

class TestEntry < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_base
		entry = Entry.new
		
		assert_instance_of(Entry, entry)
	end
	
	def test_set_title
		entry = Entry.new(nil, 'test1')
		assert_equal('test1', entry.title)
		
		entry.title = 'test2'
		assert_equal('test2', entry.title)
	end
	
	def test_set_date
		now = Date.today
		
		entry = Entry.new
		assert_equal('Date', entry.date.class.to_s)
		assert_equal(now.to_s, entry.date.to_s)
		
		entry = Entry.new(nil, 'test', '2015-02-21')
		assert_equal('Date', entry.date.class.to_s)
		assert_equal('2015-02-21', entry.date.to_s)
		
		entry.date = '2015-01-01'
		assert_equal('2015-01-01', entry.date.to_s)
		
		entry = Entry.new(nil, 'test', '2014-2-21')
		assert_equal('2014-02-21', entry.date.to_s)
		
		entry.date = '2013-1-1'
		assert_equal('2013-01-01', entry.date.to_s)
		
		entry = Entry.new(nil, 'test', Date.parse('2015-01-02'))
		assert_equal('2015-01-02', entry.date.to_s)
		
		entry = Entry.new
		entry.date = Date.today
		assert_equal(now.to_s, entry.date.to_s)
		
		entry = Entry.new
		entry.date = 1473660305
		assert_equal('2016-09-12', entry.date.to_s)
	end
	
	def test_set_date_exception
		entry = Entry.new
		
		assert_raises(ArgumentError){ entry.date = nil }
		
		# yyyy-04-31 does not exist
		assert_raises(ArgumentError){ entry.date = '2014-4-31' }
	end
	
	def test_set_revenue_expense
		entry = Entry.new
		assert_equal(0, entry.revenue)
		assert_equal(0, entry.expense)
		
		entry = Entry.new(nil, 'test', '2015-02-21', 20)
		assert_equal(20, entry.revenue)
		assert_equal(0, entry.expense)
		assert_equal(20, entry.balance)
		
		entry = Entry.new(nil, 'test', '2015-02-21', '20', '-21')
		assert_equal(20, entry.revenue)
		assert_equal(-21, entry.expense)
		assert_equal(-1, entry.balance)
		
		entry.revenue = 24
		entry.expense = -25
		assert_equal(24, entry.revenue)
		assert_equal(-25, entry.expense)
		assert_equal(-1, entry.balance)
		
		entry.revenue = 1.01
		entry.expense = -1.02
		assert_equal(1.01, entry.revenue)
		assert_equal(-1.02, entry.expense)
		assert_equal(-0.01, entry.balance)
		
		entry.revenue = 1
		entry.expense = -2.02
		assert_equal(1, entry.revenue)
		assert_equal(-2.02, entry.expense)
		assert_equal(-1.02, entry.balance)
		
		entry = Entry.new(nil, 'test', '2015-02-21', -42)
		assert_equal(0, entry.revenue)
		assert_equal(-42, entry.expense)
		assert_equal(-42, entry.balance)
		
		entry = Entry.new(nil, 'test', '2015-02-21', -30.03)
		assert_equal(0, entry.revenue)
		assert_equal(-30.03, entry.expense)
		assert_equal(-30.03, entry.balance)
		
		entry.revenue = 'string1'
		assert_equal(0, entry.revenue)
		
		entry.expense = 'string1'
		assert_equal(0, entry.expense)
		
		assert_raises(RangeError){ entry.revenue = -1.23 }
		assert_raises(RangeError){ entry.expense = 1.23 }
	end
	
	def test_set_category
		entry = Entry.new(nil, 'test', '2015-02-21', 20, 0, 'c1')
		assert_equal('c1', entry.category)
		
		entry.category = 'c2'
		assert_equal('c2', entry.category)
		
		entry.category = 1.23
		assert_equal('1.23', entry.category)
	end
	
	def test_set_comment
		entry = Entry.new(nil, 'test', '2015-02-21', 20, 0, 'c1', 'co1')
		assert_equal('co1', entry.comment)
		
		entry.comment = 'co2'
		assert_equal('co2', entry.comment)
		
		entry.comment = 1.23
		assert_equal('1.23', entry.comment)
	end
	
	def test_to_hash
		entry = Entry.new(nil, 'test', '2015-02-21', 20, -12.34, 'c3')
		
		assert_equal('2015-02-21', entry.to_h['date'].to_s)
		assert_equal(20, entry.to_h['revenue'])
		assert_equal(-12.34, entry.to_h['expense'])
		assert_equal(7.66, entry.to_h['balance'])
		assert_equal('c3', entry.to_h['category'])
	end
	
	def test_from_hash
		h = {
			'id' => 'id_foo_bar',
			'comment' => 'comment_foo_bar',
		}
		
		entry = Entry.from_h(h)
		
		assert_equal('id_foo_bar', entry.id)
		assert_equal('comment_foo_bar', entry.comment)
	end
	
end
