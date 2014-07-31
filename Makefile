PACKAGE_NAME = asp
VER=0

PREFIX = /usr/local

BINPROGS = \
	asp

MANPAGES = \
	man/asp.1

INCLUDES = \
	package.inc.sh \
	remote.inc.sh

all: $(BINPROGS) $(MANPAGES)

V_GEN = $(_v_GEN_$(V))
_v_GEN_ = $(_v_GEN_0)
_v_GEN_0 = @echo "  GEN     " $@;

edit = $(V_GEN) m4 -P $@.in >$@ && chmod go-w,+x $@

%: %.in $(INCLUDES)
	$(edit)

doc: $(MANPAGES)
man/%: man/%.txt Makefile
	$(V_GEN) a2x -d manpage \
		-f manpage \
		-a manversion=$(VERSION) \
		-a manmanual="$(PACKAGE_NAME) manual" $<

clean:
	$(RM) $(BINPROGS) $(MANPAGES)

install: all
	install -dm755 $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/share/man/man1
	install -m755 $(BINPROGS) $(DESTDIR)$(PREFIX)/bin
	install -m644 $(MANPAGES) $(DESTDIR)$(PREFIX)/share/man/man1

dist:
	git archive --format=tar --prefix=$(PACKAGE_NAME)-$(VER)/ v$(VER) | gzip -9 > $(PACKAGE_NAME)-$(VER).tar.gz
	gpg --detach-sign --use-agent $(PACKAGE_NAME)-$(VER).tar.gz

.PHONY: all clean install uninstall dist
