
GEM_NAME = thefox-wallet

include Makefile.common

.PHONY: test
test:
	RUBYOPT=-w $(BUNDLER) exec ./test/suite_all.rb -v

.PHONY: cov
cov:
	RUBYOPT=-w TZ=Europe/Vienna COVERAGE=1 $(BUNDLER) exec ./test/suite_all.rb -v

dev:
	bundler exec ./bin/wallet -w test_wallet add -t 'test' -e 5 -c 'test'
