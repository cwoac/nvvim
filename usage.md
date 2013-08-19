---
layout: default
title: index
---

#{{ page.title }}

## Installation

On unix environments, unpack and run

`make; sudo make install`

This will install it to `/usr/local/bin/` and `/usr/local/share/nvim/`. 

If you want it to go somewhere else, `export PREFIX=/blah/` first.

In gvim or in windows, copy nvim.vim somewhere appropriate and source it on vim load. (More detailed instructions to follow)


## Basic usage
I've made a quick screencast [here](http://showterm.io/3668688fe06b53482da16) outlining basic usage.

run `nvim` from the directory you want to store your notes in. You will be presented with two windows - on the right is the main pane where the note is displayed; on the left the list of search results.
The first line of the search box is the current search term.

Use `[[` to trigger vim's auto-complete with the list of available titles.

nvim binds several keys, all combos are started with the user's defined `<leader>` key. If you haven't changed this, then it is `\` by default.

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
* If you delete a note or alter the contents of notes outside of nvim, then you can refresh the database as under _importing_ below.

## Importing
If you have a bunch of notes already, then execute the following command to import them `:python nvimdb.rebuild_database()`. 

## Configuration
configuration is handled at the top of `nvim.vim`. The main one is the extension for notes. By default, nvim uses `.md` and will ignore files with any other extension.

