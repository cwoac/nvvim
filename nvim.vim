let g:extension = '.md'

function! SetupBuffer()
  30vnew  _nvim
  python buf_results = vim.current.buffer
  python win_results = vim.current.window
  python win_results_nr = vim.eval('winnr()')

  setlocal noswapfile
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal cursorline
  inoremap <buffer> <CR> <ESC>:python load_from_buffer()<CR>
  nnoremap <buffer> <CR> :python load_from_buffer()<CR>
endfunction

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

function! DefPython()
python << PYEND
import vim
import os
import xapian

db = xapian.WritableDatabase( 'nvim',xapian.DB_OPEN )
qp = xapian.QueryParser()
qp.set_stemmer( xapian.Stem( 'en' ) )
qp.set_stemming_strategy( qp.STEM_SOME )
qp.add_prefix( "title","S" )
tg = xapian.TermGenerator()
tg.set_stemmer( xapian.Stem("en") )
tg.set_stemming_strategy( tg.STEM_SOME )

e  = xapian.Enquire(db)
e.set_sort_by_value(2,False)

def update_file( filename ):
  fh = open( filename, 'r' )
  data = fh.read()
  fh.close()

  norm_file = os.path.splitext(filename.replace('_',' '))[0]

  doc = xapian.Document()
  tg.set_document(doc)

  tg.index_text( norm_file, 1, 'S' )

  tg.index_text( norm_file )
  tg.increase_termpos()
  tg.index_text( data )

  doc.add_value(1,norm_file)
  doc.add_value(2,norm_file.lower())

  doc.set_data( filename )

  id = u"Q" + norm_file
  doc.add_boolean_term( id )
  db.replace_document( id,doc )
  
def get_filename(title):
  e.set_query( qp.parse_query("title:"+title) )
  m=e.get_mset(0,db.get_doccount())
  # if we can't find an existing file, just slap .whatever on the end and make a new one
  result = title.replace(' ','_')+extension
  title_lower=title.lower()
  if not m.empty():
    for r in m:
      if r.document.get_value(1).lower()==title_lower:
        result=r.document.get_data()
        break;
  return result


def get_all():
  e.set_query(xapian.Query.MatchAll)
  return e.get_mset(0,db.get_doccount())

def get( base='' ):
  if( base=='' ):
    return get_all()
  q=qp.parse_query(base,qp.FLAG_DEFAULT|qp.FLAG_PARTIAL|qp.FLAG_WILDCARD)
  e.set_query(q)
  return e.get_mset(0,db.get_doccount())

# Looks up the values to populate the [[...]] completion box
def populate_complete(base=''):
  m  = [ "'"+r.document.get_value(1)+"'" for r in get(base) ]
  x  = ','.join(m)
  vim.command( "let g:nvim_ret=["+x+"]")

def populate_initial_buffer():
  results=get_all()
  buf_results[:]=None
  buf_results.append('----------')
  for r in results:
    buf_results.append(r.document.get_value(1))


def populate_buffer():
  search=buf_results[0]
  results=get(search)
  buf_results[1:] = None
  buf_results.append('----------')
  for r in results:
    buf_results.append(r.document.get_value(1))

# Called everytime the user presses a key when in seek mode on the title.
def handle_user( char ):
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

def set_entry_line( value ):
  buf_results[0] = value
  populate_buffer()
  win_results.cursor=(1,1)
  

def load_note( note ):
  move_to_data()
  cmd = 'edit '+note.replace(' ','\ ')
  print cmd
  vim.command(cmd )
  

def move_to_results():
  if vim.current.buffer != buf_results:
    vim.command( str(win_results_nr) + " wincmd w" )

def move_to_data():
  if vim.current.buffer == buf_results:
    vim.command( "wincmd p" )


def load_from_buffer():
  move_to_results()
  (row,_) = vim.current.window.cursor
  # convert from vim to python numbering
  row -= 1
  # Don't load the divider
  if( row==1 ):
    return

  filename = get_filename( buf_results[row] )
  load_note( filename )

  # TODO - this should probably look things up properly and be in an event
  # handler
  set_entry_line( buf_results[row] )

# Accept input into the entry line and present it accordingly. 
def handle_entry_line():
  move_to_results()
  populate_initial_buffer()
  vim.command( 'redraw' )
  is_done = False
  while not is_done:
    c = vim.eval("NVIM_getchar()")
    is_done = handle_user(c)
    vim.command("redraw")
    

# Handle loading from a link in the text
def load_from_selection():
  vim.command( 'normal yi]' )
  name = vim.eval( '@"' )
  filename = get_filename( name )
  load_note( filename )
  set_entry_line( name )

PYEND
endfunction

function! NVIM_setup_data()
  set completefunc=CompleteNVIM
  set completeopt=menu,menuone,longest
  set ignorecase
  set infercase
  set autowriteall
endfunction


function! CompleteNVIM(findstart,base)
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

call NVIM_setup_data()
call SetupBuffer()
call DefPython()
python populate_initial_buffer()
python extension = vim.eval('g:extension')

inoremap        [[ [[]]<Left><Left><C-x><C-u>
inoremap        <silent>  <Leader>i <ESC>:python handle_entry_line()<CR>
nnoremap        <silent>  <Leader>i :python handle_entry_line()<CR>
nnoremap        <silent>  <Leader><CR> :python load_from_selection()<CR>
inoremap        <silent>  <Leader><CR> <ESC>:python load_from_selection()<CR>

augroup nvim_group
  autocmd!
  autocmd BufWritePost,FileWritePost,FileAppendPost * :python update_file( vim.eval('@%') )
  autocmd BufNew * :call NVIM_setup_data()
augroup END
