#!/bin/sh

rm -r test
mkdir test
cd test

cat >> first.md << EOF
This is the [[first]] file, to be followed by the [[second]] one.
EOF

cat >> second.md << EOF
Now the [[second]] file.

Previously there was the [[first]]; soon there will be a [[third]].
EOF

vim -S ../plugin/nvim.vim -c 'exec NVIM_init()' -c 'py nvimdb.rebuild_database()' -c 'py nvim_debug=True'
