#!/usr/bin/env ruby -w

require 'bundler/setup'
require 'minitest/autorun'
require 'wallet'
#require 'wallet/entry'

class TestWallet < MiniTest::Test
	def test_base
		wallet = Wallet::Wallet.new('wallet_test')
		
		assert_equal('Wallet::Wallet', wallet.class.to_s)
		assert_equal(true, Dir.exist?('wallet_test'))
	end
	
	def test_add
		wallet = Wallet::Wallet.new('wallet_test')
		
		wallet.add Wallet::Entry.new('2014-01-01', 100)
		wallet.add Wallet::Entry.new('2014-01-02', -10)
		wallet.add Wallet::Entry.new('2015-01-01', 100)
		wallet.add Wallet::Entry.new('2015-01-02', -10)
		wallet.add Wallet::Entry.new('2015-02-21', 20)
		wallet.add Wallet::Entry.new('2015-02-21', -5)
		wallet.add Wallet::Entry.new('2015-02-21', -1.5)
		wallet.add Wallet::Entry.new('2015-02-22', 10)
		
		puts wallet.balance.to_s
		
		assert_equal(true, File.exist?('wallet_test/data/month_2015_02.yml'))
		
		# File.unlink 'wallet_test/data/month_2015_02.yml'
		# Dir.unlink 'wallet_test/data'
		# Dir.unlink 'wallet_test'
	end
	
	def test_exceptions
		wallet = Wallet::Wallet.new('wallet_test')
		
		assert_raises(ArgumentError){ wallet.add 12 }
	end
end
