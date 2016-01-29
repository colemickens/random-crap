#!/usr/bin/env bash

set -x

git reset --hard azure/master
git clean -xdf

###

rm -rf Godeps
git add -A .
git commit -m "[glide] remove godeps"
sleep 1

###

find . -not -iwholename '*.git' -type f -print0 | xargs -0 sed -i "s|github.com/Azure/azure-sdk-for-go/Godeps/_workspace/src/||g"
git add -A .
git commit -m "[glide] remove Godep path rewriting"
sleep 1

####

glide init
glide install
go build ./... || { echo "go build failed. try again."; exit; }
git add -A .
git commit -m "[glide] glide init"

####

find ./arm/ -name '*.go' -type f -exec gofmt -s -w {} \;

git add -A .
git commit -m "[glide] gofmt everything"

####

set -e

test -z "$(gofmt -s -l $(find ./arm/* -type d -print) | tee /dev/stderr)"
test -z "$(gofmt -s -l -w management | tee /dev/stderr)"
test -z "$(gofmt -s -l -w storage | tee /dev/stderr)"
go build -v ./...
test -z "$(go vet $(find ./arm/* -type d -print) | tee /dev/stderr)"
test -z "$(golint ./arm/... | tee /dev/stderr)"
test -z "$(golint ./storage/... | tee /dev/stderr)"
go vet ./storage/...
go test -v ./management/...
test -z "$(golint ./management/... |  grep -v 'should have comment' | grep -v 'stutters' | tee /dev/stderr)"
