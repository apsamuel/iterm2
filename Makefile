.PHONY: install

install:
	git submodule update --init --recursive
	ln -sfn $(CURDIR) $(HOME)/.iterm2
