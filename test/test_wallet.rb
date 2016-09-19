#!/usr/bin/env ruby

require 'minitest/autorun'
require 'fileutils'
require 'wallet'


class TestWallet < MiniTest::Test
	
	include TheFox::Wallet
	
	def test_that_it_has_a_version_number
		refute_nil(::TheFox::Wallet::VERSION)
	end
	
	def test_base
		wallet = Wallet.new('wallet_test')
		
		assert_instance_of(Wallet, wallet)
		assert_equal(true, !Dir.exist?('wallet_test'))
	end
	
	def test_add1
		wallet = Wallet.new('wallet_test')
		
		wallet.add(Entry.new(nil, 'test', '2014-01-01', 100))
		wallet.add(Entry.new(nil, 'test', '2014-01-01', 50))
		wallet.add(Entry.new(nil, 'test', '2014-01-01', -10))
		wallet.add(Entry.new(nil, 'test', '2014-01-02', -10))
		wallet.add(Entry.new(nil, 'test', '2015-01-01', 100, 0, 'c1'))
		wallet.add(Entry.new(nil, 'test', '2015-01-02', 0, -10, 'c2'))
		wallet.add(Entry.new(nil, 'test', '2015-02-21', 20))
		wallet.add(Entry.new(nil, 'test', '2015-02-21', 0, -5, 'c1'))
		wallet.add(Entry.new(nil, 'test', '2015-02-21', 0, -1.5, 'c2'))
		wallet.add(Entry.new(nil, 'test', '2015-02-22', 10))
		
		sum = wallet.sum
		assert_equal(280, sum[:revenue])
		assert_equal(-36.5, sum[:expense])
		assert_equal(243.5, sum[:balance])
		
		sum = wallet.sum(2014)
		assert_equal(150, sum[:revenue])
		assert_equal(-20, sum[:expense])
		assert_equal(130, sum[:balance])
		
		sum = wallet.sum(2014, 1)
		assert_equal(150, sum[:revenue])
		assert_equal(-20, sum[:expense])
		assert_equal(130, sum[:balance])
		
		sum = wallet.sum(2014, 1, 1)
		assert_equal(150, sum[:revenue])
		assert_equal(-10, sum[:expense])
		assert_equal(140, sum[:balance])
		
		sum = wallet.sum(2015)
		assert_equal(130, sum[:revenue])
		assert_equal(-16.5, sum[:expense])
		assert_equal(113.5, sum[:balance])
		
		sum = wallet.sum(2015, 1)
		assert_equal(100, sum[:revenue])
		assert_equal(-10, sum[:expense])
		assert_equal(90, sum[:balance])
		
		sum = wallet.sum(2015, 2)
		assert_equal(30, sum[:revenue])
		assert_equal(-6.5, sum[:expense])
		assert_equal(23.5, sum[:balance])
		
		sum = wallet.sum(2015, 2, 21)
		assert_equal(20, sum[:revenue])
		assert_equal(-6.5, sum[:expense])
		assert_equal(13.5, sum[:balance])
		
		sum = wallet.sum(2015, 2, 22)
		assert_equal(10, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(10, sum[:balance])
		
		sum = wallet.sum(nil, nil, nil, 'c1')
		assert_equal(100, sum[:revenue])
		assert_equal(-5, sum[:expense])
		assert_equal(95, sum[:balance])
		
		sum = wallet.sum(2014, nil, nil, 'c1')
		assert_equal(0, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(0, sum[:balance])
		
		sum = wallet.sum(2014, 1, nil, 'c1')
		assert_equal(0, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(0, sum[:balance])
		
		sum = wallet.sum(2014, 1, 1, 'c1')
		assert_equal(0, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(0, sum[:balance])
		
		sum = wallet.sum(2015, nil, nil, 'c1')
		assert_equal(100, sum[:revenue])
		assert_equal(-5, sum[:expense])
		assert_equal(95, sum[:balance])
		
		sum = wallet.sum(2015, 1, nil, 'c1')
		assert_equal(100, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(100, sum[:balance])
		
		sum = wallet.sum(2015, 1, 1, 'c1')
		assert_equal(100, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(100, sum[:balance])
		
		sum = wallet.sum(2015, 2, nil, 'c1')
		assert_equal(0, sum[:revenue])
		assert_equal(-5, sum[:expense])
		assert_equal(-5, sum[:balance])
		
		sum = wallet.sum(2015, 2, 1, 'c1')
		assert_equal(0, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(0, sum[:balance])
		
		sum = wallet.sum(2015, 2, 21, 'c1')
		assert_equal(0, sum[:revenue])
		assert_equal(-5, sum[:expense])
		assert_equal(-5, sum[:balance])
		
		sum = wallet.sum(nil, nil, nil, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(-11.5, sum[:expense])
		assert_equal(-11.5, sum[:balance])
		
		sum = wallet.sum(2014, nil, nil, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(0, sum[:balance])
		
		sum = wallet.sum(2014, 1, nil, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(0, sum[:balance])
		
		sum = wallet.sum(2014, 1, 1, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(0, sum[:balance])
		
		sum = wallet.sum(2015, nil, nil, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(-11.5, sum[:expense])
		assert_equal(-11.5, sum[:balance])
		
		sum = wallet.sum(2015, 1, nil, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(-10, sum[:expense])
		assert_equal(-10, sum[:balance])
		
		sum = wallet.sum(2015, 1, 1, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(0, sum[:balance])
		
		sum = wallet.sum(2015, 2, nil, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(-1.5, sum[:expense])
		assert_equal(-1.5, sum[:balance])
		
		sum = wallet.sum(2015, 2, 1, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(0, sum[:expense])
		assert_equal(0, sum[:balance])
		
		sum = wallet.sum(2015, 2, 21, 'c2')
		assert_equal(0, sum[:revenue])
		assert_equal(-1.5, sum[:expense])
		assert_equal(-1.5, sum[:balance])
		
		assert_equal(['default', 'c1', 'c2'], wallet.categories)
	end
	
	def test_add2
		wallet = Wallet.new('wallet_test')
		
		assert_equal(true, wallet.add(Entry.new(nil, 'test', '2014-01-01', 1)))
		assert_equal(true, wallet.add(Entry.new(nil, 'test', '2014-01-01', 1), true))
		
		assert_equal(true, wallet.add(Entry.new(1, 'test', '2014-01-01', 1), true))
		assert_equal(false, wallet.add(Entry.new(1, 'test', '2014-01-01', 1), true))
		
		assert_equal(true, wallet.add(Entry.new('my_id', 'test', '2014-01-01', 1), true))
		assert_equal(false, wallet.add(Entry.new('my_id', 'test', '2014-01-01', 1), true))
		assert_equal(true, wallet.add(Entry.new('my_id', 'test', '2014-01-01', 1), false))
	end
	
	def test_exceptions
		wallet = Wallet.new('wallet_test')
		
		assert_raises(ArgumentError) do
			wallet.add(12)
		end
	end
	
	def test_find_entry_by_id
		wallet = Wallet.new('wallet_test')
		
		wallet.add(Entry.new(nil, 'test', '2014-01-01', -1))
		wallet.add(Entry.new(1, 'test', '2014-01-01', 1))
		wallet.add(Entry.new(2, 'test', '2014-01-02', 2))
		wallet.add(Entry.new(3, 'test', '2015-03-04', 3))
		
		found_entry = wallet.find_entry_by_id(1)
		assert_instance_of(Entry, found_entry)
		assert_equal(1, found_entry.id)
		
		found_entry = wallet.find_entry_by_id(2)
		assert_instance_of(Entry, found_entry)
		assert_equal(2, found_entry.id)
		
		found_entry = wallet.find_entry_by_id(3)
		assert_instance_of(Entry, found_entry)
		assert_equal(3, found_entry.id)
		
		assert_nil(wallet.find_entry_by_id(4))
		assert_nil(wallet.find_entry_by_id(5))
		assert_nil(wallet.find_entry_by_id(6))
	end
	
	def teardown
		FileUtils.rm_r('wallet_test', {:force => true})
	end
	
end
