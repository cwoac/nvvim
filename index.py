#!/usr/bin/env python2

import os
import sys
import xapian
import re

extension = '.md'


def index( path, file, db,tg ):
  # create termgenerator

  full_path = os.path.join( path, file )

  fh = open( full_path, 'r' )
  data = fh.read()
  fh.close()

  norm_file = os.path.splitext(file.replace('_',' '))[0]

  doc = xapian.Document()
  tg.set_document(doc)

  tg.index_text( norm_file, 1, 'S' )

  tg.index_text( norm_file )
  tg.increase_termpos()
  tg.index_text( data )

  doc.add_value(1,norm_file)
  doc.add_value(2,norm_file.lower())

  doc.set_data( file )

  id = u"Q" + norm_file
  doc.add_boolean_term( id )
  db.replace_document( id,doc )

#index( sys.argv[1], sys.argv[2] )

db = xapian.WritableDatabase( 'nvim', xapian.DB_CREATE_OR_OPEN )
tg = xapian.TermGenerator()
tg.set_stemmer( xapian.Stem("en") )
tg.set_stemming_strategy( tg.STEM_SOME )
dir = sys.argv[1]
dirs = os.listdir(dir)
for file in dirs:
  if file.endswith(extension):
    index( dir,file,db,tg )
  
