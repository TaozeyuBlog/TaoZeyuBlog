#!/bin/bash

checkError()
{
    if [[ "${1}" -ne "0" ]]; then
        echo "*** Error: ${2}"
        exit ${1}
    fi
}

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  echo "This is a pull request. No publish will be done."
  exit 0
fi
if [ "$TRAVIS_BRANCH" != "master" ]&&[ "$TRAVIS_BRANCH" != "develop" ]; then
  echo "Testing on the branch $TRAVIS_BRANCH other than master/develop. No publish will be done."
  exit 0
fi

cd Moskize91.github.io
git remote remove origin
git remote add origin https://$GH_TOKEN@github.com/Moskize91/Moskize91.github.io.git
git add -A .
git commit -m "update by travis."
git push origin master

checkError $? "Publish Success."
