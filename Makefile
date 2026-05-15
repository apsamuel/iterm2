.PHONY: install dump-prefs

install:
	ln -sfn $(CURDIR) $(HOME)/.iterm2

dump-prefs:
	./scripts/dump-preferences.sh
