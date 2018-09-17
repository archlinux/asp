PACKAGE_NAME = asp

VERSION := $(shell git describe --dirty 2>/dev/null)

PREFIX = /usr/local

BINPROGS = \
	asp

MANPAGES = \
	man/asp.1

BASH_COMPLETION = \
	shell/bash-completion

ZSH_COMPLETION = \
	shell/zsh-completion

INCLUDES = \
	archweb.inc.sh \
	package.inc.sh \
	remote.inc.sh \
	util.inc.sh

all: $(BINPROGS) $(MANPAGES)

V_GEN = $(_v_GEN_$(V))
_v_GEN_ = $(_v_GEN_0)
_v_GEN_0 = @echo "  GEN     " $@;

edit = $(V_GEN) m4 -P $@.in | sed 's/@ASP_VERSION@/$(VERSION)/' >$@ && chmod go-w,+x $@

%: %.in $(INCLUDES)
	$(edit)

doc: $(MANPAGES)
man/%: man/%.txt Makefile
	$(V_GEN) a2x \
		-d manpage \
		-f manpage \
		-a manversion="$(PACKAGE_NAME) $(VERSION)" \
		-a manmanual="$(PACKAGE_NAME) manual" $<

check: $(BINPROGS)
	@for f in $(BINPROGS); do bash -O extglob -n $$f; done

clean:
	$(RM) $(BINPROGS) $(MANPAGES)

install: all
	install -dm755 $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/share/man/man1
	install -m755 $(BINPROGS) $(DESTDIR)$(PREFIX)/bin
	install -m644 $(MANPAGES) $(DESTDIR)$(PREFIX)/share/man/man1
	install -Dm644 $(BASH_COMPLETION) $(DESTDIR)$(PREFIX)/share/bash-completion/completions/asp
	install -Dm644 $(ZSH_COMPLETION) $(DESTDIR)$(PREFIX)/share/zsh/site-functions/_asp

.PHONY: all clean install uninstall dist
