#!/usr/bin/env sh

# abort on errors
set -e

# build
npm run build

# navigate into the build output directory
cd dist

git push -f git@github.com:christopher-masselli/WalmartReceiptScanner.git master

# git push -f git@github.com:christopher-masselli/christopher-masselli.github.io.git master