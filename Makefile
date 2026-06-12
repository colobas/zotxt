.PHONY: clean test unittest dist

NODE_BIN ?= /opt/homebrew/opt/node@22/bin
VERSION=$(shell jq .version extension/manifest.json -r)
NPM = PATH="$(NODE_BIN):$$PATH" npm

dist: test zotxt-$(VERSION).xpi ;

notest: zotxt-$(VERSION).xpi ;

zotxt-$(VERSION).xpi: extension/*.js extension/resource/translators/EasyKeyExporter.js 
	cd extension && zip -r ../zotxt-$(VERSION).xpi *

clean:
	rm -f zotxt-*.xpi

unittest:
	$(NPM) test

test: unittest
	cd test && ruby test.rb
