PREFIX?=/usr/local
PHONY=clean


nvim: nvim.base
				sed "s|PREFIX|${PREFIX}|" $< > $@

install: nvim.vim nvim
				install -m 755 -D nvim ${PREFIX}/bin/nvim
				install -m 644 -D nvim.vim ${PREFIX}/share/nvim/nvim.vim

clean:
				rm nvim || true
