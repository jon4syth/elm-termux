#!/data/data/com.termux/files/usr/bin/bash

exec proot -b "$PWD/etc:/etc" ./bin/elm "$@"
