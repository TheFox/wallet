
GEM_NAME = thefox-wallet

include Makefile.common

.PHONY: test
test:
	RUBYOPT=-w $(BUNDLER) exec ./tests/ts_all.rb

dev:
	RUBYOPT=-rbundler/setup ruby ./bin/wallet
