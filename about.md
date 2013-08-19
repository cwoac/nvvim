---
layout: default
title: index
---

#{{ page.title }}

NVim is a clone of the mac app [Notational Velocity][nv] in vim.

It is designed for fast[^1] plain-text[^2] note-taking *and retrieval*

## Features

* Wide platform support:
  Console or gui, any platform that supports vim, xapian and python should work.
* Mouse-less operation:
  Searching, filtering and navigating between notes can all be done from keyboard shortcuts.
* Single interface for searching and note creation:
  Hit `\ i` and start typing. If the note exists it will appear in the search results. If not hit `return` and a new one will be created.
* Interlink notes:
  Type `[[` and a pop-up menu of note names will appear.
  Move your cursor over a link and hit `\ <enter>` to jump straight to that note, automatically updating the search box with relevant notes.
* Note renaming and deletion from within vim:
  Use `\ r` and `\ d`
* The power of vim:
  Use all the keyboard tricks and plugins[^3] you love.
* Language specific word-stemming.
  Thanks to [xapian][], search terms are automatically stemmed, so searches for `happiness` will match (to a lower amount) `happy`, `happiest`, etc.

[nv]: http://notational.net
[xapian]: http://xapian.org

[^1]: On my test atom netbook, indexing 1.7mb of notes spread across ~300 files takes about 10s. Searching is instantaneous.
[^2]: By default NVim uses '.md' as an extension so your notes will be highlighted as Markdown documents, but you can configure this.
[^3]: In theory, as long as you leave the search window visible and another window open then nvim should run alongside any other plugins.
