# nvvim

A [Notational Velocity][nv] inspired mode for [vim][]. 


## Requirements
This should work on any recent vim compiled with `+python3`. You will also need the [xapian][] library and python bindings.

## Installation
Easiest way is to use [pathogen][]:

````
cd ~/.vim/bundle
git clone git://github.com/cwoac/nvvim.git
````

Or if you manage things yourself, copy `nvvim.vim` into your `~/.vim/plugins` directory and `nvvim.py` into `~/.vim/python`

### Script

NVim is not intended to be used in every vim session you open; to this end it will not be activated until you `:Nvim`

There is a supplied script `nvvim` which will open vim and call this to drop you directly into nvvim mode; simply copy it to somewhere on your path

## Usage

I've made a quick screencast [here](http://showterm.io/3668688fe06b53482da16) outlining basic usage.

nvvim stores its notes and database within a single directory. Either:

* export `NVIM_HOME=path/to/directory` and run `nvvim`.
* run `nvvim path/to/directory` or
* run `nvvim` from within that directory. 

You will then be presented with two windows - on the right is the main pane where the note is displayed; on the left the list of search results.
The first line of the search box is the current search term.

Use `[[` to trigger vim's auto-complete with the list of available titles.

nvvim binds several keys, all combos are started with the user's defined `<leader>` key. If you haven't changed this, then it is `\` by default.

* `\<F5>`  Invoke NVIM on the current directory. This is the only key bound until NVIM has been invoked once. Hitting it a second time will do nothing.
* `\<cr>`  This will follow a '[[...]]' link from within a note.
* `\l` Move the cursor to the search area ready for changes.
* `\i` As `\l`, but clears the current search term first (equivalent to `<esc>` on NV as remapping escape in vim is... unwise)
* `\d` Delete a note. **warning** This will delete the note pointed to by the search bar. Under normal usage this should be correct. 
 It does not currently ask confirmation.
* `\r` Rename a note. This will *not* update any links in other notes.


Note that if you try an load a note that does not exist, the system will create a new one.

The full range of vim commands are available to you, but there are a couple of things to bear in mind:

* Autosave is turned on
* You can create new windows via splits or whatever as you wish - when a note is loaded from the search results it will be loaded into the most recently used window.
* If you close the results window (or all windows apart from the results window) you will need to close and reopen vim.
* If you delete a note or alter the contents of notes outside of nvvim, then you can refresh the database as under _importing_ below.

### Configuration
Most of the configuration is handled at the top of `nvvim.vim`. These are:

* `NVIM_extension` - the extension to use for files, and hence vim filetype detection. nvvim will ignore any files in the directory that do not end with this.
* `NVIM_language` - the language stemmer to use when parsing notes (requires xapian 1.1+). The list of availiable languages/stemmers depends on your version of xapian, but the normal set is listed [here](http://xapian.org/docs/apidoc/html/classXapian_1_1Stem.html#0f8f250587dfef35d47f13f0ec0028fb).
* `NVIM_side` - which side of the screen the sidebar should be on. Defaults to the left.
* `NVIM_database` - the name for the directory used to store note metadata. You probably shouldn't change this unless you are fairly sure you know what you are doing.
* `NVIM_interactive` - Whether to map the leader based commands in interactive mode.

If you use vim under a different name (e.g. `mvim` for macvim) then you can still use the nvvim script by setting the `NVIM_EDITOR` environment variable.

by default nvvim allows multiple note directories. The downside to this is it requires being run from the directory containing all your notes. 
If you would rather have a single note directory, then you can shorthand this by setting the `NVIM_HOME` environment variable and using the nvvim script.

### Importing
If you have a bunch of notes already, then execute the following command to import them `:python nvimdb.rebuild_database()`. 

## Contributing
Contributions are welcome; just submit a normal pull request. By doing so you assert that these changes are yours to submit and that you are providing these changes 'as-is' and that I may do whatever I wish with them.

## Renaming
Due to the ever increasing popularity of Neovim and it's choice to pick nvim as it's shortname, I have renamed this to nvvim to avoid conflicts.

### Contributors
Thanks to:

[@Nixon](https://github.com/Nixon)
[@AzizLight](https://github.com/AzizLight)
[@Keithbsmiley](https://github.com/Keithbsmiley)
[@colons](https://github.com/colons)
[@shoaibkamil](https://github.com/shoaibkamil)
[@eklenske](https://github.com/eklenske)

### dynamic python (i.e. Arch Linux)
If your installation of vim is compiled using dynamic linking (e.g. Arch linux), then nvvim requires libpython3.so to be preloaded or it won't work. the `nvvim` script should handle this for you. If you are invoking nvvim by hand, set `LD_PRELOAD=/path/to/libpython3.so`. The script assumes this file is in `/usr/lib/libpython3.so`, which is the normal location. If for some reason it is elsewhere, then you will need to set the `NVIM_PYTHON3_SO` environment variable accordingly.
This may have some additional unintended consequences - for one thing, plugins which depend on python2 will almost certainly crash vim while using nvvim via dynamic python3.

### Nixos

I have added a default.nix for development under nixos. To use, switch to the src directory and run `nix-shell --pure`

## TODO
Quite a few things, although the code is quite usable as-is.

* Allow hiding/reshowing the search results
* Some proper documentation (screencasts!)

 [nv]: http://www.notational.net
 [vim]: http://www.vim.org
 [xapian]: http://xapian.org
 [pathogen]: https://github.com/tpope/vim-pathogen
