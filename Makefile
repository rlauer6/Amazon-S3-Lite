#-*- mode: makefile; -*-
SHELL := /bin/bash

.SHELLFLAGS := -ec

VERSION := $(shell cat VERSION)

%.pm: %.pm.in
	sed -e 's/[@]PACKAGE_VERSION[@]/$(VERSION)/' < $< > $@

%.pl: %.pl.in
	sed -e 's/[@]PACKAGE_VERSION[@]/$(VERSION)/' < $< > $@
	chmod +x $@

PERL_MODULES = \
    lib/Amazon/S3/Lite.pm \
    lib/Amazon/S3/Lite/Logger.pm \
    lib/Amazon/S3/Lite/Credentials.pm

BIN_FILES = 

TARBALL = Amazon-S3-Lite-$(VERSION).tar.gz

DEPS = \
    buildspec.yml \
    $(PERL_MODULES) \
    $(BIN_FILES) \
    requires \
    test-requires \
    README.md

all: $(TARBALL)

$(TARBALL): $(DEPS)
	make-cpan-dist.pl -b $<

README.md: lib/Amazon/S3/Lite.pm
	pod2markdown $< > $@

include version.mk

include release-notes.mk

CLEANFILES = \
    $(BIN_FILES) \
    $(PERL_MODULES) \
    *.tar.gz \
    *.tmp \
    extra-files \
    provides \
    resources \
    resources \
    release-*.{lst,diffs}

clean:
	rm -f $(CLEANFILES)
