#!/bin/bash
git pull
cd snestistics
git fetch
git reset --hard origin/master
rm -r docs
cp -r ../docs .
cd utilities
/c/python3/python command-line-parsing.py
cd ..
git commit -a -m "Homepage updates"
git push
cd ..
git add snestistics


