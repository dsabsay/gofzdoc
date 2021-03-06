#!/bin/bash
set -euo pipefail

source ./gofzdoc
set +x
set -euo pipefail

function assert_eq() {
    if [[ "$1" != "$2" ]]; then
        echo "FAIL: Expected '$2', got '$1'"
        exit 1
    fi
}

function test_get_pkg_and_symbol() {
    # Functions
    in='os func Getenv(key string) string'
    result=$(__gofzdoc_get_pkg_and_symbol "$in")
    assert_eq "$result" "os Getenv"

    # Types
    in='archive/tar type Writer struct {'
    result=$(__gofzdoc_get_pkg_and_symbol "$in")
    assert_eq "$result" "archive/tar Writer"

    # Constants and variables
    in='bytes const MinRead = 512'
    result=$(__gofzdoc_get_pkg_and_symbol "$in")
    assert_eq "$result" "bytes MinRead"

    in='bytes var ErrTooLarge = errors.New("bytes.Buffer: too large")'
    result=$(__gofzdoc_get_pkg_and_symbol "$in")
    assert_eq "$result" "bytes ErrTooLarge"

    in='archive/zip 	ErrFormat    = errors.New("zip: not a valid zip file")'
    result=$(__gofzdoc_get_pkg_and_symbol "$in")
    assert_eq "$result" "archive/zip ErrFormat"

    in='archive/zip 	Deflate uint16 = 8 // DEFLATE compressed'
    result=$(__gofzdoc_get_pkg_and_symbol "$in")
    assert_eq "$result" "archive/zip Deflate"

    # Methods
    in='html/template func (t *Template) Execute(wr io.Writer, data interface{}) error'
    result=$(__gofzdoc_get_pkg_and_symbol "$in")
    assert_eq "$result" "html/template Template.Execute"

    in='html/template func (t *Template) ParseFiles(filenames ...string) (*Template, error)'
    result=$(__gofzdoc_get_pkg_and_symbol "$in")
    assert_eq "$result" "html/template Template.ParseFiles"
}

function test_gofzdoc_filter() {
    mkdir -p tmp/
    cd tmp/
    __gofzdoc_filter "cat ../tests/all.txt" "archive/zip" > all.out
    diff ../tests/all.expect all.out
}

test_get_pkg_and_symbol
test_gofzdoc_filter

echo 'OK'
