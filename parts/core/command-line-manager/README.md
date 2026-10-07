# Command-line manager

Signs UKI command-line addons for Secure Boot with the device key in the
TPM. The TPM signs only an addon the server authorized, and only until a
newer authorization is used.

The scripts are in `tpm/`. They are installed to `/usr/lib/puavo-core`
with the prefix `puavo-command-line-manager-`. The examples use the
installed names and a directory `keys` with the device key
`secure-boot.priv` and its certificate `secure-boot.pem`.

## Load the device key

    puavo-command-line-manager-load keys

Imports the device key into the TPM. The TPM uses it only under a
policy signed by the server key, `/etc/puavo-conf/server.pub`. The load
also defines the signing counter. Its files go to
`/run/puavo/command-line`.

Until a server key is configured, make a placeholder key pair first:

    puavo-command-line-manager-placeholder-keys

It writes `server.priv` and `server.pub` to `/run/puavo/command-line`.

## Authorize an addon

The server needs the signing counter of the device once:

    $ puavo-command-line-manager-counter
    42

The server builds an addon and authorizes it for the device:

    ukify build --section=.cmdline:quiet --output=addon.efi
    puavo-command-line-manager-authorize addon.efi keys/secure-boot.pem \
        server.priv 43 bundle.json

The bundle lets this device sign this addon while its counter is at
most 43. Authorizing needs no TPM.

## Sign the addon

    puavo-command-line-manager-sign keys bundle.json signed.efi
    sbverify --cert keys/secure-boot.pem signed.efi

The TPM signs the addon and the counter rises to 43. Bundles with a
lower value stop working.

## Signing request programs

`puavo-command-line-sign-request` and `puavo-command-line-sign-assemble`
split the signing of a PE binary in two. `request` makes a signing
request with the information to sign. `assemble` puts the pieces and
the signature together into the signed binary. They build on
sbsigntools, which `scripts/setup` fetches and patches.

## Tests

    make test

The tests run against a software TPM.
