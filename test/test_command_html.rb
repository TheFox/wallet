#!/usr/bin/env ruby

# Test HTML Command

require 'minitest/autorun'
require 'pathname'
require 'fileutils'
require 'wallet'

class TestHtmlCommand < MiniTest::Test
  
  include TheFox::Wallet
  
  def test_command
    wallet_path = Pathname.new('tmp/wallet_test')
    wallet = Wallet.new(wallet_path)
    
    # Add test data.
    wallet.add(Entry.new(nil, 'test', '2014-01-01', 100))
    wallet.add(Entry.new(nil, 'test', '2015-01-01', 50))
    wallet.add(Entry.new(nil, 'test', '2016-01-01', 50))
    
    cmd = HtmlCommand.new({:wallet_path => wallet_path})
    cmd.run
  end
  
  # Clean up.
  def teardown
    FileUtils.rm_rf('tmp/wallet_test')
  end
  
end
