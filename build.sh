#!/usr/bin/env bash

INITPWD=$(pwd)
GOPATH=$INITPWD/.gopath

if [[ -e $GOPATH ]]; then
	echo "Removing $GOPATH"
	rm -rf $GOPATH
fi

mkdir -p $GOPATH/src/github.com/documize
git clone git@github.com:portablecloud/documize.git $GOPATH/src/github.com/documize/community

cd $GOPATH/src/github.com/documize/community/gui
npm install

cd $GOPATH/src/github.com/documize/community

NOW=$(date)
echo "Build process started $NOW"

echo "Building Ember assets..."
cd gui
ember b -o dist-prod/ --environment=production

echo "Copying Ember assets..."
cd ..
rm -rf embed/bindata/public
mkdir -p embed/bindata/public
cp -r gui/dist-prod/assets embed/bindata/public
cp -r gui/dist-prod/codemirror embed/bindata/public/codemirror
cp -r gui/dist-prod/tinymce embed/bindata/public/tinymce
cp -r gui/dist-prod/sections embed/bindata/public/sections
cp gui/dist-prod/*.* embed/bindata
cp gui/dist-prod/favicon.ico embed/bindata/public
rm -rf embed/bindata/mail
mkdir -p embed/bindata/mail
cp core/api/mail/*.html embed/bindata/mail
cp core/database/templates/*.html embed/bindata
rm -rf embed/bindata/scripts
mkdir -p embed/bindata/scripts
cp -r core/database/scripts/autobuild/*.sql embed/bindata/scripts

echo "Generating in-memory static assets..."
go get -u github.com/jteeuwen/go-bindata/...
go get -u github.com/elazarl/go-bindata-assetfs/...
cd embed
go generate
cd ../

echo "Building the binary."
docker run --rm -i -t -e GOPATH=/gopath -v $GOPATH/src/github.com/documize/community:/gopath/src/github.com/documize/community -w /gopath/src/github.com/documize/community golang:1.8 \
	go build -v -ldflags='-linkmode external -extldflags "-static"' -o /gopath/src/github.com/documize/community/documize ./edition/community.go
cd $INITPWD

cp $GOPATH/src/github.com/documize/community/documize $INITPWD/image

echo "Finished."

docker build -t "nucleosinc/documize" ./image

#git clone git@github.com:portablecloud/documize.git
#mkdir 