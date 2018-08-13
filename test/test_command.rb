#!/usr/bin/env ruby

# Test Basic Command

require 'minitest/autorun'
require 'wallet'

class TestCommand < MiniTest::Test
  
  include TheFox::Wallet
  
  def test_create_by_name
    cmd = Command.create_by_name('add')
    
    assert_instance_of(AddCommand, cmd)
  end
  
  def test_create_by_name_exception
    assert_raises(RuntimeError){ Command.create_by_name('invalid') }
  end
  
end
