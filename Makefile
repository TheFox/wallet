
GEM_NAME = thefox-wallet

include Makefile.common

.PHONY: dev
dev:
	$(BUNDLER) exec ./bin/wallet -w wallet_test2 add -t 'test' -e 5 -c 'test'

.PHONY: test
test:
	RUBYOPT=-w $(BUNDLER) exec ./test/suite_all.rb -v

.PHONY: cov
cov:
	RUBYOPT=-w TZ=Europe/Vienna COVERAGE=1 $(BUNDLER) exec ./test/suite_all.rb -v

.PHONY: cov_local
cov_local:
	RUBYOPT=-w TZ=Europe/Vienna SIMPLECOV_PHPUNIT_LOAD_PATH=../simplecov-phpunit COVERAGE=1 $(BUNDLER) exec ./test/suite_all.rb -v
