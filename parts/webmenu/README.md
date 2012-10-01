# Web Menu


## Installing

Install Node.js 0.8.x, wmctrl and git

```
sudo add-apt-repository ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install nodejs npm nodejs-dev wmctrl git-core

git clone https://github.com/opinsys/webmenu.git
cd webmenu/
make
npm start
```

## Menu item

Add launcher with

    wget http://localhost:1337 -q -O -

:)
