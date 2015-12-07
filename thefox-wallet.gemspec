# coding: UTF-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'wallet/version'

Gem::Specification.new do |spec|
	spec.name          = 'thefox-wallet'
	spec.version       = TheFox::Wallet::VERSION
	spec.date          = TheFox::Wallet::DATE
	spec.author        = 'Christian Mayer'
	spec.email         = 'christian@fox21.at'
	
	spec.summary       = %q{Finances Tracking}
	spec.description   = %q{A Ruby library for tracking your finances.}
	spec.homepage      = TheFox::Wallet::HOMEPAGE
	spec.license       = 'GPL-3.0'
	
	spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
	spec.bindir        = 'bin'
	spec.executables   = ['wallet']
	spec.require_paths = ['lib']
	spec.required_ruby_version = '>=2.2.0'
	
	spec.add_development_dependency 'bundler', '~>1.10'
	spec.add_development_dependency 'rake', '~>10.0'
	spec.add_development_dependency 'pry', '~>0.10'
	spec.add_development_dependency 'minitest', '~>5.7'
	
	spec.add_dependency 'ArgsParser', '~>1.0'
end
