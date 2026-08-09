# Elm on Termux

This repository is a minimal reproducible proof-of-concept showing that the official Elm 0.19.2 compiler can run successfully in Termux.

The important part is not a custom Elm build, `proot-distro`, chroot, or full Linux userspace. The workaround is to provide the conventional Linux `/etc` files that the official binary expects, while still running directly inside Termux.

## Requirements

Install the required Termux packages:

```sh
pkg update
pkg install curl proot gzip
```

- `curl` downloads the official Elm release.
- `gzip` provides gunzip to extract the compressed Elm release.
- `proot` provides the temporary `/etc` bind mount required by Elm.

## Setup

From a fresh checkout, make the setup script executable and run it:

```sh
chmod +x setup-elm.sh
./setup-elm.sh
```

The script relies on `$PREFIX`, Termux's installation prefix. It:

1. Downloads the official Elm 0.19.2 release asset from GitHub.
2. Extracts it.
3. Creates `bin/` and places the compiler at `./bin/elm`.
4. Creates the local `etc/` compatibility filesystem.
5. Copies Termux's DNS configuration and TLS certificate bundle into that tree.
6. Verifies that the Elm binary can start.

The setup prepares both:

- `./bin/elm` — the Elm compiler.
- `etc/` — the repository-local compatibility files required by Elm.

The downloaded release is the official GitHub asset: [`elm-0.19.2-linux-arm.gz`](https://github.com/elm/compiler/releases/download/0.19.2/elm-0.19.2-linux-arm.gz).

Although the asset name contains `linux-arm`, the downloaded binary was verified with `file` as:

```text
ELF 64-bit LSB executable, ARM aarch64, statically linked, stripped
```

## Running Elm

After running the setup script, use `elm.sh` to run Elm

The `elm.sh` wrapper automatically runs Elm with the required `/etc` compatibility bind mount, so `proot` does not need to be invoked manually.

For example:

    ./elm.sh --version
    ./elm.sh make src/Main.elm

The REPL can also be started through the wrapper:

    ./elm.sh repl

Other Elm commands can be passed through in the same way:

    ./elm.sh init
    ./elm.sh install elm/http
    ./elm.sh make src/Main.elm

Internally, `elm.sh` runs the compiler through `proot` using the repository's local compatibility filesystem.

This compiles the example application from `src/Main.elm` and generates `index.html`.

Expected successful result:

    Success! Compiled 1 module.

        Main ───> index.html

## Why this is needed

Normal Termux networking already works. The compatibility issue is that Elm expects standard Linux system files at conventional paths such as:

- `/etc/resolv.conf`
- `/etc/ssl/cert.pem`
- `/etc/ssl/certs/ca-certificates.crt`

Termux stores the relevant files under `$PREFIX` instead, for example:

- `$PREFIX/etc/resolv.conf`
- `$PREFIX/etc/tls/cert.pem`

`setup-elm.sh` copies those files into the repository's local `etc/` compatibility tree as:

- `etc/resolv.conf`
- `etc/ssl/cert.pem`
- `etc/ssl/certs/ca-certificates.crt`

This does not modify Termux's real `/etc`, replace Termux configuration, or permanently alter the Termux environment. The `proot -b "$PWD/etc:/etc" ...` bind mount only makes the repository-local tree visible as `/etc` to the Elm process for the duration of that command.

No Linux distribution, `proot-distro`, chroot, or full Linux ARM64/aarch64 userspace is required.

## Verified behavior

With this workaround, Elm was verified to:

- resolve `package.elm-lang.org`;
- establish an HTTPS connection;
- verify the server certificate;
- download Elm package dependencies;
- compile the example Elm application successfully.

The repository uses Elm 0.19.2, as declared in `elm.json`.
