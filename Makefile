
GEM_NAME = thefox-wallet

include Makefile.common

.PHONY: test
test:
	RUBYOPT=-w $(BUNDLER) exec ./tests/suite_all.rb

dev:
	RUBYOPT=-rbundler/setup ruby ./bin/wallet
