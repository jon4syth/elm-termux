#!/data/data/com.termux/files/usr/bin/bash

set -e

ELM_VERSION="0.19.2"
ELM_URL="https://github.com/elm/compiler/releases/download/$ELM_VERSION/elm-$ELM_VERSION-linux-arm.gz"

mkdir -p bin
mkdir -p etc/ssl/certs

echo "Downloading Elm $ELM_VERSION..."
curl -L "$ELM_URL" -o "elm-$ELM_VERSION-linux-arm.gz"

gunzip -f "elm-$ELM_VERSION-linux-arm.gz"
mv "elm-$ELM_VERSION-linux-arm" "bin/elm"

chmod +x bin/elm

cp "$PREFIX/etc/resolv.conf" etc/resolv.conf
cp "$PREFIX/etc/tls/cert.pem" etc/ssl/cert.pem
cp "$PREFIX/etc/tls/cert.pem" etc/ssl/certs/ca-certificates.crt

echo
echo "Elm installed:"
./bin/elm --help >/dev/null
echo "OK"
