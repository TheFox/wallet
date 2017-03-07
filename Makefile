
GEM_NAME = thefox-wallet

include Makefile.common

.PHONY: dev
dev:
	$(BUNDLER) exec ./bin/wallet -w wallet_test2 add -t 'Taxes Q1' -e 5 -c Company

.PHONY: test
test:
	RUBYOPT=-w $(BUNDLER) exec ./test/suite_all.rb -v

.PHONY: cov
cov:
	RUBYOPT=-w TZ=Europe/Vienna COVERAGE=1 $(BUNDLER) exec ./test/suite_all.rb -v

.PHONY: cov_local
cov_local:
	RUBYOPT=-w TZ=Europe/Vienna SIMPLECOV_PHPUNIT_LOAD_PATH=../simplecov-phpunit COVERAGE=1 $(BUNDLER) exec ./test/suite_all.rb -v

README.html: README.md
	mkreadme

watch_readme:
	while true; do \
		$(MAKE) README.html; \
		sleep 1; \
	done
