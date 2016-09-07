#!/bin/bash

mkdir Moskize91.github.io
cd Moskize91.github.io
git init
git remote add origin https://$GIT_NAME:$GIT_PASSWORD@git.coding.net/moskize/moskize.git
git remote update origin
git checkout master
git merge origin/master