#!/usr/bin/env ruby

if ENV['COVERAGE'] && ENV['COVERAGE'].to_i != 0
	require 'simplecov'
	require 'simplecov-phpunit'
	
	SimpleCov.formatter = SimpleCov::Formatter::PHPUnit
	SimpleCov.start do
		add_filter 'test'
	end
end

require_relative 'test_wumber'
# require_relative 'test_revenue'
# require_relative 'test_expense'
require_relative 'test_command'
require_relative 'test_command_add'
require_relative 'test_command_categories'
require_relative 'test_command_csv'
require_relative 'test_command_html'
require_relative 'test_command_list'
require_relative 'test_entry'
require_relative 'test_wallet'
