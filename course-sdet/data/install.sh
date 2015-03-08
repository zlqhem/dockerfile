#!/bin/bash

# step 0. prepare findlib
(cd findlib-1.5.5 && ./configure && make install)

# step 0. prepare yices smt solver
mkdir -p /home/jburnim
cp -r yices /home/jburnim/yices-1.0.11

# step 0. prepare crest source
wget https://github.com/jburnim/crest/archive/v0.1.2.zip -O crest-v0.1.2.zip
unzip crest-v0.1.2.zip

# step 1. build crest-cil
(cd crest-0.1.2/cil && ./configure && make)

# step 1. build crest
(cd crest-0.1.2/src && make)

# step 2. pathc: crest/bin/crestc
(cp crestc.patch crest-0.1.2/bin && cd crest-0.1.2/bin && patch crestc crestc.patch)

