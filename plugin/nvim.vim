" File: nvim.vim
" Author: Oliver Matthews <oliver@codersoffortune.net>

" Load guard {{{
if exists('g:NVIM_loaded') || &cp
  finish
endif
let g:NVIM_loaded    = 1
let s:plug = expand("<sfile>:p:h:h")

"Lazy initialisation
let g:NVIM_intialised = 0
"}}}

" Configuration options {{{

" The extension used for files.
" Anything *not* ending in this will be ignored.
let g:NVIM_extension = '.md'
" The directory used for the note database
let g:NVIM_database  = '.nvim'
" The language used for xapian stemming
let g:NVIM_language  = 'en'
" Which side you want the sidebar on. valid choices are 'right','left'.
let g:NVIM_side = 'left'
" Map interactive mode leader commands
let g:NVIM_interactive = 1
"}}}

" External Functions {{{

" function NVIM_init {{{
" Initialises the search bar
function! NVIM_init()
  if g:NVIM_intialised == 1
    return
  endif
  echom "Initialising"
  if g:NVIM_side ==? "right"
    let g:NVIM_sidecmd = 'setlocal splitright'
  else
    let g:NVIM_sidecmd = 'setlocal nosplitright'
  endif
  call s:SetupData()
  call s:SetupResults()
  call s:DefPython()


  " search highlighting
  set hlsearch

  " clear previous search terms
  let @/=''

  inoremap        [[ [[]]<Left><Left><C-x><C-u>
  nnoremap        <silent>  <Leader>i :python handle_new_search()<CR>
  nnoremap        <silent>  <Leader>l :python handle_search()<CR>
  nnoremap        <silent>  <Leader><CR> :python load_from_selection()<CR>
  nnoremap        <silent>  <Leader>d :python delete_current_note()<CR>
  nnoremap        <silent>  <Leader>r :python rename_note()<CR>
  if g:NVIM_interactive == 1
    inoremap        <silent>  <Leader>i <ESC>:python handle_new_search()<CR>
    inoremap        <silent>  <Leader>l <ESC>:python handle_search()<CR>
    inoremap        <silent>  <Leader><CR> <ESC>:python load_from_selection()<CR>
    inoremap        <silent>  <Leader>d <ESC>:python delete_current_note()<CR>
    inoremap        <silent>  <Leader>r <ESC>:python rename_note()<CR>
  endif
  augroup nvim_group
    autocmd!
    autocmd BufWritePost,FileWritePost,FileAppendPost * :python nvimdb.update_file( vim.eval('@%') )
    autocmd BufNew * :call s:SetupData()
  augroup END


  let g:NVIM_intialised = 1
endfunction
" }}}

" function NVIM_getchar {{{
" calls getchar and converts it to a value python can use.
" Needs to be external scope to allow calls from python
function! NVIM_getchar()
  let c = getchar()
  if c =~ '^\d\+$'
    let c = nr2char(c)
  endif
  if c=="\<BS>"
    let c = nr2char(10)
  endif
  if c=="\<Esc>"
    let c = nr2char(27)
  endif
  if c=="\<Down>"
    let c = nr2char(17)
  endif
  return c
endfunction
" }}}

" function NVIM_complete {{{
" omnicomplete function for nvim
function! NVIM_complete(findstart,base)
    if a:findstart
        " get last [
        " strictly speaking unneeded unless the user does some funky remaps
        let line = getline('.')
        let start = col('.')-1
        while start > 0 && line[start-1] != '['
            let start -= 1
        endwhile
        return start
    else
        let g:nvim_ret = []
        python populate_complete(vim.eval('a:base'))
        return g:nvim_ret
    endif
endfunction
" }}}
" }}}

" Internal Functions {{{
" function s:SetupResults {{{
" creates the results window
function! s:SetupResults()
  execute g:NVIM_sidecmd
  30vnew  _nvim

  setlocal noswapfile
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal cursorline
  setlocal winfixwidth
  inoremap <buffer> <CR> <ESC>:python load_from_buffer()<CR>
  nnoremap <buffer> <CR> :python load_from_buffer()<CR>
endfunction
" }}}

" Initalizes the python functions
function! s:DefPython() " {{{
  let s:script = s:plug . '/python/nvim.py'
  execute 'pyfile ' . s:script
endfunction
" }}}

" function s:SetupData {{{
" Called on all new buffers to set local options
function! s:SetupData()
  set completefunc=NVIM_complete
  set completeopt=menu,menuone,longest
  set ignorecase
  set infercase
  set autowriteall
endfunction
" }}}
"}}}

" Initialisation code {{{
command!                          Nvim  call NVIM_init()
nnoremap        <silent>  <Leader><F5> :call NVIM_init()<CR>
" }}}
