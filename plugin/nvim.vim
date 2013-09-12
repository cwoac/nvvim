" File: nvim.vim
" Author: Oliver Matthews <oliver@codersoffortune.net>

" Load guard {{{
if exists('g:NVIM_loaded') || &cp
  finish
endif
let g:NVIM_loaded    = 1

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
"}}}

" External Functions {{{

" function NVIM_init {{{
" Initialises the search bar
function! NVIM_init()
  if g:NVIM_intialised == 1
    return
  endif
  echom "Initialising"
  call s:SetupData()
  call s:SetupResults()
  call s:DefPython()


  " search highlighting
  set hlsearch
  " clear previous search terms
  let @/=''

  inoremap        [[ [[]]<Left><Left><C-x><C-u>
  inoremap        <silent>  <Leader>i <ESC>:python handle_new_search()<CR>
  nnoremap        <silent>  <Leader>i :python handle_new_search()<CR>
  inoremap        <silent>  <Leader>l <ESC>:python handle_search()<CR>
  nnoremap        <silent>  <Leader>l :python handle_search()<CR>
  inoremap        <silent>  <Leader><CR> <ESC>:python load_from_selection()<CR>
  nnoremap        <silent>  <Leader><CR> :python load_from_selection()<CR>
  inoremap        <silent>  <Leader>d <ESC>:python delete_current_note()<CR>
  nnoremap        <silent>  <Leader>d :python delete_current_note()<CR>
  inoremap        <silent>  <Leader>r <ESC>:python rename_note()<CR>
  nnoremap        <silent>  <Leader>r :python rename_note()<CR>

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
  30vnew  _nvim

  setlocal noswapfile
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal cursorline
  inoremap <buffer> <CR> <ESC>:python load_from_buffer()<CR>
  nnoremap <buffer> <CR> :python load_from_buffer()<CR>
endfunction
" }}}

" Declares all the python functions in the code
function! s:DefPython() " {{{
python << PYEND
import vim
import os
import xapian
import shutil

# Handles the connection to the xapian database
class Nvimdb: # {{{
  # constructor
  def __init__( self ): # {{{
    self.extension = vim.eval('g:NVIM_extension')
    self.database  = vim.eval('g:NVIM_database')
    self.language  = vim.eval('g:NVIM_language')
    self.reload_database()
  #}}}

  def reload_database( self ): # {{{
    # create the xapian handlers
    self.db = xapian.WritableDatabase( self.database,xapian.DB_CREATE_OR_OPEN )

    self.qp = xapian.QueryParser()
    self.qp.set_stemmer( xapian.Stem( self.language ) )
    self.qp.set_stemming_strategy( self.qp.STEM_SOME )
    self.qp.add_prefix( "title","S" )

    self.tg = xapian.TermGenerator()
    self.tg.set_stemmer( xapian.Stem( self.language ) )
    try:
        self.tg.set_stemming_strategy( self.tg.STEM_SOME )
    except AttributeError:
        pass

    self.e  = xapian.Enquire(self.db)
    self.sorted_e = xapian.Enquire(self.db)
    # Value 2 is the lowercase form of the title
    self.sorted_e.set_sort_by_value(2,False)

  #}}}
    
  def rebuild_database( self ): # {{{
    self.db.close()
    shutil.rmtree( self.database )
    self.reload_database()
    for f in os.listdir(os.getcwd()):
      if f.endswith(self.extension):
        self.update_file(f)
    populate_buffer()
  #}}}

  def update_file( self,filename ): # {{{
    fh = open( filename, 'r' )
    data = fh.read()
    fh.close()

    norm_file = os.path.splitext(filename.replace('_',' '))[0]

    doc = xapian.Document()
    self.tg.set_document(doc)

    self.tg.index_text( norm_file, 1, 'S' )

    self.tg.index_text( norm_file )
    self.tg.increase_termpos()
    self.tg.index_text( data )

    doc.add_value(1,norm_file)
    doc.add_value(2,norm_file.lower())

    doc.set_data( filename )

    id = u"Q" + norm_file
    doc.add_boolean_term( id )
    self.db.replace_document( id,doc )
  #}}}
  
  def get_filename( self,title ): # {{{
    self.e.set_query( self.qp.parse_query("title:"+title) )
    m=self.e.get_mset(0,self.db.get_doccount())
    # if we can't find an existing file, create a new one by putting the default 
    # extension on the end of the (munged) title
    result = title.replace('/','_').replace('\\','_')+self.extension
    title_lower=title.lower()
    if not m.empty():
      for r in m:
        if r.document.get_value(1).lower()==title_lower:
          result=r.document.get_data()
          break;
    return result
  #}}}

  # Retrieve every document in the database.
  def get_all( self ): # {{{
    self.sorted_e.set_query(xapian.Query.MatchAll)
    return self.sorted_e.get_mset(0,self.db.get_doccount())
  #}}}

  def get( self,base='' ): # {{{
    if( base=='' ):
      return self.get_all()
    q=self.qp.parse_query(base,self.qp.FLAG_DEFAULT|self.qp.FLAG_PARTIAL|self.qp.FLAG_WILDCARD)
    self.e.set_query(q)
    return self.e.get_mset(0,self.db.get_doccount())
  #}}}


#END CLASS
#}}}

# Looks up the values to populate the [[...]] completion box
def populate_complete( base='' ): #{{{
  m  = [ "'"+r.document.get_value(1)+"'" for r in nvimdb.get(base) ]
  x  = ','.join(m)
  vim.command( "let g:nvim_ret=["+x+"]")
#}}}

def populate_initial_buffer(): #{{{
  results=nvimdb.get_all()
  buf_results[:]=None
  redraw_buffer( results )
#}}}

def populate_buffer(): #{{{
  search=buf_results[0]
  results=nvimdb.get(search)
  vim.command('let @/="'+search+'"')
  redraw_buffer( results )
#}}}

def redraw_buffer( results ): #{{{
  buf_results[1:] = None
  buf_results.append('----------')
  for r in results:
    buf_results.append(r.document.get_value(1))
#}}}

# Called everytime the user presses a key when in seek mode on the title.
# Returns True iff the user has hit a key which should terminate input.
# TODO - implement Left/Right key support
def handle_user( char ): #{{{
  if char == '\r': # Carriage return
    load_from_buffer()
    return True
  if char == chr(10): # backspace
    buf_results[0] = buf_results[0][:-1]
    populate_buffer()
    return False
  if char == chr(27): # escape
    return True
  if char == chr(17): # One we are using for down arrow
    vim.command('normal 2j')
    return True

  # it's just a normal character
  buf_results[0]+=char
  populate_buffer()
  return False
#}}}

def set_entry_line( value ): #{{{
  buf_results[0] = value
  populate_buffer()
  win_results.cursor=(1,1)
#}}}
  
def move_to_results(): #{{{
  if vim.current.buffer != buf_results:
    vim.command( str(win_results_nr) + " wincmd w" )
# }}}    

def move_to_data(): #{{{
  if vim.current.buffer == buf_results:
    vim.command( "wincmd p" )
# }}}

def load_note( note ): #{{{
  move_to_data()
  cmd = 'edit '+note.replace(' ','\ ')
  vim.command(cmd )
# }}}

def delete_note( filename ): #{{{
  move_to_data()
  vim.command( "enew" )
  filename = nvimdb.get_filename( buf_results[0] )
  if not filename:
    return
  os.remove(filename)
  buf_results[0] = ""
  nvimdb.rebuild_database()
#}}}

def delete_current_note(): #{{{
  # TODO - can we ensure we are deleting the right one?
  # TODO - ask for confirmation?
  # clear the old window
  filename = nvimdb.get_filename( buf_results[0] )
  delete_note( filename )
#}}}

def rename_note(): #{{{
  move_to_data()
  oldname = nvimdb.get_filename( buf_results[0] )
  vim.command( 'call inputsave()')
  vim.command( 'let g:NVIM_newname=input("Enter new name:")' )
  vim.command( 'call inputrestore()')
  newname = vim.eval( 'g:NVIM_newname' )
  # Allow aborts
  if not newname:
    return
  # make sure it has the right extension
  if not newname.endswith( nvimdb.extension ):
    newname = newname + nvimdb.extension
  # TODO check for success
  # write out under the new name
  vim.command( 'write '+newname )
  # remove the old file
  delete_note( oldname )
  # reload it into the buffer under the new name
  load_note( newname )

#}}}

def load_from_buffer(): #{{{
  move_to_results()
  (row,_) = vim.current.window.cursor
  # convert from vim to python numbering
  row -= 1
  # Don't load the divider
  if( row==1 ):
    return
  # Don't create an empty note
  if not buf_results[row]:
    return

  filename = nvimdb.get_filename( buf_results[row] )
  load_note( filename )

  # TODO - this should probably look things up properly and be in an event
  # handler, but it seems to work.
  set_entry_line( buf_results[row] )
# }}}

# Accept input into the entry line and present it accordingly. 
def handle_search(): #{{{
  move_to_results()
  is_done = False
  while not is_done:
    c = vim.eval("NVIM_getchar()")
    is_done = handle_user(c)
    vim.command("redraw")
#}}}    

# Clear the search term and accept new input.
def handle_new_search(): #{{{
  move_to_results()
  populate_initial_buffer()
  vim.command( 'redraw' )
  is_done = False
  while not is_done:
    c = vim.eval("NVIM_getchar()")
    is_done = handle_user(c)
    vim.command("redraw")
#}}}    

# Handle loading from a link in the text
def load_from_selection(): #{{{
  # make sure the buffer is cleared
  vim.command( "let @n=''" )
  vim.command( 'normal "nyi]' )
  name = vim.eval( '@n' )
  if not name:
    return
  filename = nvimdb.get_filename( name )
  load_note( filename )
  # TODO - remove if/when we put it in an onload handler
  set_entry_line( name )
# }}}

# Python intiialisation code
buf_results = vim.current.buffer
win_results = vim.current.window
win_results_nr = vim.eval('winnr()')
nvimdb = Nvimdb()
populate_initial_buffer()
PYEND
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
nnoremap        <silent>  <Leader><F5> :call NVIM_init()<CR>
" }}}
