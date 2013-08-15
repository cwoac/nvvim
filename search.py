import sys
import xapian

# TODO - make this centralised
database = '.nvim'

def search( db, query, offset=0, pagesize=10 ):
  qp = xapian.QueryParser()
  qp.set_stemmer( xapian.Stem("en") )
  qp.set_stemming_strategy( qp.STEM_SOME )
  qp.add_prefix( "title","S" )

  q = qp.parse_query( query )

  e = xapian.Enquire(db)
  e.set_query(q)

  matches=[]
  for match in e.get_mset(offset,pagesize):
    print u"%(rank)i: (%(id)s) %(title)s" % {
        'rank': match.rank + 1,
        'id' : match.docid,
        'title': match.document.get_data()
      }
    matches.append(match.docid)

  return matches



db = xapian.Database( database )
m = search( db, " ".join(sys.argv[1:]),0,40 )
