#!/usr/bin/env bash

# Check for Nodejs.
if ! which node > /dev/null; then
  echo "This project requires Node.js to build the source. Please check the installation instructions on https://nodejs.org/"
  exit 1
fi

# Check for Coffeescript.
if [ `npm list -g | grep -c coffeescript` -eq 0 ]; then
  echo "Installing Coffeescript..."
  npm install -g coffeescript
fi

# Check for Sass.
if [ `npm list -g | grep -c sass` -eq 0 ]; then
  echo "Installing Sass..."
  npm install -g sass
fi

# Build the distribution.
echo "Starting build..."
cd source && cake sbuild > /dev/null
echo "Build done!"
