# debbox

Upload `.deb` files and execute commands on them.

## Configuration

Create `/etc/debbox.json`

    {
        "debCommand": "deb-release $1"
    }


`debCommand` will be executed for each uploaded `.deb` file. `$1` will be
absolute path to the uploaded file.

## Curl usage

Upload single file

    curl --form "deb=@package.deb" http://localhost:8080/deb

Upload multiple files in single request

    curl --form "deb=@package1.deb" --form "deb=@package1.deb" http://localhost:8080/deb

## Install

    npm install

Start server with

    node index.js
