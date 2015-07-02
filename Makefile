
RM = rm -rf
VENDOR = vendor
BUNDLER = bundle

.PHONY: all install update test clean

all: install

install: $(VENDOR)

update:
	$(BUNDLER) update

test:
	./tests/ts_all.rb

clean:
	$(RM) .bundle
	$(RM) $(VENDOR)
	$(RM) Gemfile.lock

$(VENDOR):
	$(BUNDLER) install --path vendor/bundle
