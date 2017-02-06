#!/bin/sh
rm site
# -package haskell98
ghc -threaded -o site site.hs
rm -f *.hi
rm -f *.o
./site clean
./site build
