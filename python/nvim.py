''' Python part of nvim module.
'''
import os
import shutil
import tempfile
import xapian
import vim


def nvim_rmtree_error(func, path, exc_info):  # {{{
    ''' Debug function for handling wipe database errors. '''
    exctype, value = exc_info()[:2]
    debug("failed (" + func + ") on " + path + ": " + exctype + " : " + value)
#}}}


class Nvimdb:  # {{{
    ''' Class to handle connection to xapian database.
    '''
    # constructor

    def __init__(self):  # {{{
        self.extension = vim.eval('g:NVIM_extension')
        self.database = vim.eval('g:NVIM_database')
        self.language = vim.eval('g:NVIM_language')
        self.reload_database()
    #}}}

    def reload_database(self):  # {{{
        ''' reload the database. '''
        # create the xapian handlers
        self.database = xapian.WritableDatabase(
            self.database, xapian.DB_CREATE_OR_OPEN)

        self.query_parser = xapian.QueryParser()
        # needed for incremental search
        self.query_parser.set_database(self.database)
        self.query_parser.set_stemmer(xapian.Stem(self.language))
        self.query_parser.set_stemming_strategy(self.query_parser.STEM_SOME)
        self.query_parser.add_prefix("title", "S")

        self.term_generator = xapian.TermGenerator()
        self.term_generator.set_stemmer(xapian.Stem(self.language))
        try:
            self.term_generator.set_stemming_strategy(
                self.term_generator.STEM_SOME)
        except AttributeError:
            pass

        self.enquire = xapian.Enquire(self.database)
        self.sorted_e = xapian.Enquire(self.database)
        # Value 2 is the lowercase form of the title
        self.sorted_e.set_sort_by_value(2, False)

    #}}}

    def rebuild_database(self):  # {{{
        ''' delete (if applicable) and recreate the database.
        '''
        debug("rebuild_database in " + os.getcwd())
        self.database.close()
        tmpdir = tempfile.mkdtemp(prefix='.', dir=os.getcwd())
        debug("tmpdir:" + tmpdir)
        os.rename(self.database, os.path.join(tmpdir, self.database))
        shutil.rmtree(tmpdir, onerror=nvim_rmtree_error)
        self.reload_database()
        base_dir = os.getcwd()
        for file_name in os.listdir(base_dir):
            if file_name.endswith(self.extension):
                file_path = os.path.join(base_dir, file_name)
                if not os.path.isdir(file_path):
                    self.update_file(file_name)
        populate_buffer()
    #}}}

    def update_file(self, filename):  # {{{
        ''' update a single file's entry in the db.
        '''
        debug("update_file on " + filename)
        data = open(filename, 'r').read()

        norm_file = os.path.splitext(filename.replace('_', ' '))[0]

        doc = xapian.Document()
        self.term_generator.set_document(doc)

        self.term_generator.index_text(norm_file, 1, 'S')

        self.term_generator.index_text(norm_file)
        self.term_generator.increase_termpos()
        self.term_generator.index_text(data)

        doc.add_value(1, norm_file)
        doc.add_value(2, norm_file.lower())

        doc.set_data(filename)

        file_id = "Q{}".format(norm_file)
        doc.add_boolean_term(file_id)
        self.database.replace_document(file_id, doc)
    #}}}

    def get_filename(self, title):  # {{{
        ''' Determine the text file associated with a given title.
        '''
        self.enquire.set_query(self.query_parser.parse_query("title:" + title))
        match_set = self.enquire.get_mset(0, self.database.get_doccount())
        # if we can't find an existing file, create a new one by putting the default
        # extension on the end of the (munged) title
        result = title.replace('/', '_').replace('\\', '_') + self.extension
        title_lower = title.lower()
        if not match_set.empty():
            for result in match_set:
                if result.document.get_value(1).lower() == title_lower:
                    result = result.document.get_data()
                    break
        return result
    #}}}

    def get_all(self):  # {{{
        ''' Retrieve every document in the database.
        '''
        self.sorted_e.set_query(xapian.Query.MatchAll)
        return self.sorted_e.get_mset(0, self.database.get_doccount())
    #}}}

    def get(self, base=''):  # {{{
        ''' look up a term in the database.
        '''
        if base == '':
            return self.get_all()
        query = self.query_parser.parse_query(base,
                                              self.query_parser.FLAG_DEFAULT
                                              | self.query_parser.FLAG_PARTIAL
                                              | self.query_parser.FLAG_WILDCARD)
        self.enquire.set_query(query)
        return self.enquire.get_mset(0, self.database.get_doccount())
    #}}}


# END CLASS
#}}}

def debug(msg):
    ''' enables / disables printing debug output. '''
    if nvim_debug:
        # first need to sanitize the message
        import re
        msg = re.subn("'", "''", msg)[0]
        vim.command("echom '" + msg + "'")


def populate_complete(base=''):  # {{{
    ''' Looks up the values to populate the [[...]] completion box.
    '''
    hits = ["'" + r.document.get_value(1) + "'" for r in nvimdb.get(base)]
    result = ','.join(hits)
    vim.command("let g:nvim_ret=[" + result + "]")
#}}}


def populate_initial_buffer():  # {{{
    ''' draws the initial screen showing all documents.
    '''
    results = nvimdb.get_all()
    buf_results[:] = None
    redraw_buffer(results)
#}}}


def populate_buffer():  # {{{
    ''' reruns the search then draws the buffer.
    '''
    search = buf_results[0]
    results = nvimdb.get(search)
    vim.command('let @/="' + search + '"')
    redraw_buffer(results)
#}}}


def redraw_buffer(results):  # {{{
    ''' draws the buffer.
    '''
    buf_results[1:] = None
    buf_results.append('----------')
    for result in results:
        buf_results.append(result.document.get_value(1))
#}}}

def handle_user(char):  # {{{
    ''' Called everytime the user presses a key when in seek mode on the title.
        Returns True iff the user has hit a key which should terminate input.
        TODO - implement Left/Right key support
    '''

    if char == '\r':  # Carriage return
        load_from_buffer()
        return True
    if char == chr(10):  # backspace
        buf_results[0] = buf_results[0][:-1]
        populate_buffer()
        return False
    if char == chr(27):  # escape
        return True
    if char == chr(17):  # One we are using for down arrow
        vim.command('normal 2j')
        return True

    # it's just a normal character
    buf_results[0] += char
    populate_buffer()
    return False
#}}}


def set_entry_line(value):  # {{{
    ''' set the entry line and regenerate the results buffer.
    '''
    buf_results[0] = value
    populate_buffer()
    win_results.cursor = (1, 1)
#}}}


def move_to_results():  # {{{
    ''' Make sure we are on the results buffer.
    '''
    if vim.current.buffer != buf_results:
        vim.command(str(win_results_nr) + " wincmd w")
# }}}


def move_to_data():  # {{{
    ''' Make sure we are on the data buffer.
    '''
    if vim.current.buffer == buf_results:
        vim.command("wincmd p")
# }}}


def load_note(note):  # {{{
    ''' loads a note into the window.
    '''
    debug("load_note on " + note)
    move_to_data()
    cmd = 'edit ' + note.replace(' ', r'\ ')
    vim.command(cmd)
# }}}


def delete_note(filename):  # {{{
    ''' deletes a given note.
    '''
    debug("delete_note called for " + filename)
    move_to_data()
    vim.command("enew")
    os.remove(filename)
    buf_results[0] = ""
    nvimdb.rebuild_database()
#}}}


def delete_current_note():  # {{{
    ''' deletes the currently open note.'''
    filename = ""
    # TODO - ask for confirmation?
    if vim.current.buffer != buf_results:
        filename = nvimdb.get_filename(buf_results[0])
    else:
        # TODO - abstract this out of load_from_buffer
        (row, _) = vim.current.window.cursor
        # convert from vim to python numbering
        row -= 1
        # Don't load the divider
        if row == 1:
            return
        # Don't create an empty note
        if not buf_results[row]:
            return
        filename = nvimdb.get_filename(buf_results[row])
    if not filename:
        return
    delete_note(filename)
#}}}


def rename_note():  # {{{
    '''renames a note.'''
    debug("rename_note")
    move_to_data()
    oldname = nvimdb.get_filename(buf_results[0])
    vim.command('call inputsave()')
    vim.command('let g:NVIM_newname=input("Enter new name:")')
    vim.command('call inputrestore()')
    newname = vim.eval('g:NVIM_newname')
    # Allow aborts
    if not newname:
        return
    # make sure it has the right extension
    if not newname.endswith(nvimdb.extension):
        newname = newname + nvimdb.extension
    debug("Going to rename " + oldname + " to " + newname)
    # TODO check for success
    # TODO ensure it doesn't already exist?
    # write out under the new name
    vim.command('write ' + newname)
    # remove the old file
    delete_note(oldname)
    # reload it into the buffer under the new name
    load_note(newname)

#}}}


def load_from_buffer():  # {{{
    ''' load the currently selected note in the search results.
    '''
    move_to_results()
    (row, _) = vim.current.window.cursor
    # convert from vim to python numbering
    row -= 1
    # Don't load the divider
    if row == 1:
        return
    # Don't create an empty note
    if not buf_results[row]:
        return

    filename = nvimdb.get_filename(buf_results[row])
    load_note(filename)

    # TODO - this should probably look things up properly and be in an event
    # handler, but it seems to work.
    set_entry_line(buf_results[row])
# }}}


def handle_search():  # {{{
    ''' Accept input into the entry line and present it accordingly.
    '''
    move_to_results()
    is_done = False
    while not is_done:
        char = vim.eval("NVIM_getchar()")
        is_done = handle_user(char)
        vim.command("redraw")
#}}}


def handle_new_search():  # {{{
    ''' Clear the search term and accept new input.
    '''
    move_to_results()
    populate_initial_buffer()
    vim.command('redraw')
    is_done = False
    while not is_done:
        char = vim.eval("NVIM_getchar()")
        is_done = handle_user(char)
        vim.command("redraw")
#}}}


def load_from_selection():  # {{{
    ''' Handle loading from a link in the text.
    '''
    # make sure the buffer is cleared
    vim.command("let @n=''")
    vim.command('normal "nyi]')
    name = vim.eval('@n')
    if not name:
        return
    filename = nvimdb.get_filename(name)
    load_note(filename)
    # TODO - remove if/when we put it in an onload handler
    set_entry_line(name)
# }}}


# Python initialisation code
buf_results = vim.current.buffer
win_results = vim.current.window
win_results_nr = vim.eval('winnr()')
nvim_debug = True
nvimdb = Nvimdb()
populate_initial_buffer()
