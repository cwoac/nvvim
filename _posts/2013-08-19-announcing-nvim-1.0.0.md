---
title: Announcing NVim v1.0.0
subtitle: Notational velocity in vim
layout: news
---

## NVim

[Nvim][] is an clone of some of the main features of [Notational Velocity][nv] as a vim script.

NV/NValt remain one of the best arguments in favour of using OSX. A fast, efficient note-taking system that can be controlled entirely though the keyboard. 
Its combined search / title bar means you can just tell it what you want and you get the information you need or the ability to create a new note from the same command.
Unfortunately the codebase is too heavily dependant on OSX to make a port viable. 

Nvim is implemented as a vim script that is compatible with both vim and gvim, so it can be used in both as a gui app and in a terminal and on any platform that runs the requirements[^1]

## Download
The latest code is availiable from [github][nvim], or you can download v1.0.0 in either [zip][] or [tar.gz][] formats.

Full instructions are located in the [README][] file.


[nv]: http://notational.net
[nvim]: https://github.com/cwoac/nvim
[zip]: https://github.com/cwoac/nvim/archive/v1.0.0.zip
[tar.gz]: https://github.com/cwoac/nvim/archive/v1.0.0.tar.gz
[README]: https://github.com/cwoac/nvim/blob/master/README.md

[^1]: vim, python2, xapian
