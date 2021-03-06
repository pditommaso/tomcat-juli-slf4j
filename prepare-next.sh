#!/bin/bash

set -e

if [ "$1" != "-f" ]; then
#  if ! git diff-index --quiet HEAD --; then
#    echo "Have staged or working tree changes. Exiting."
#    exit 1
#  fi

  if ! git diff-files --quiet; then
    echo "Have working tree changes. Exiting."
    exit 1
  fi
fi

set -u

git pull

TOMCAT_VERSION=`sed -n "s/^.*<tomcat.version>\(.*\)<\/.*$/\1/p" pom.xml | head -n 1`

if [ -z ${NEXT_VERSION+x} ]; then
  NEXT_VERSION=`sed -n "s/^.*<version>\(.*\)-SNAPSHOT.*$/\1/p" pom.xml`

  ARRV=(${TOMCAT_VERSION//./ })
  MAJOR=${ARRV[0]}
  MINOR=${ARRV[1]}
  PATCH=${ARRV[2]}

  let PATCHINC=PATCH+1
  EXPECTED_NEXT_VERSION=$MAJOR.$MINOR.$PATCHINC

  echo "Next version: $NEXT_VERSION"

  if [ "$NEXT_VERSION" != "$EXPECTED_NEXT_VERSION" ]; then
    echo "Expected next version: $EXPECTED_NEXT_VERSION"
    echo "Error (1)"
    exit 1
  fi
else 
  echo "Next version: $NEXT_VERSION"
fi


sed -i -e "s/<tomcat.version>$TOMCAT_VERSION<\/tomcat.version>/<tomcat.version>$NEXT_VERSION<\/tomcat.version>/g" pom.xml

git diff pom.xml

TOMCAT_VERSION_NOW=`sed -n "s/^.*<tomcat.version>\(.*\)<\/.*$/\1/p" pom.xml | head -n 1`
if [ "$NEXT_VERSION" != "$TOMCAT_VERSION_NOW" ]; then
  echo "Error (2)"
  exit 1
fi

mvn clean install
git add pom.xml
git commit -m "Prepare $NEXT_VERSION"