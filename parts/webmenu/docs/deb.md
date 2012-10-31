# Debian package building

  1. Install `devscripts` package
  1. Do source installation
  1. Copy compiled appjs node modules to `webmenu/node_modules`
  1. Checkout the debian branch
  1. Rebase to master
  1. Extract node.js binary tarball to ./nodejs

```
wget http://nodejs.org/dist/v0.8.14/node-v0.8.14-linux-x64.tar.gz
tar xzvf node-v0.8.14-linux-x64.tar.gz
rm node-v0.8.14-linux-x64.tar.gz 
mv node-v0.8.14-linux-x64 nodejs
```

  7. Update `debian/changelog` with `dch`
  8. Go to the parent dir and execute `./webmenu/builddeb.sh`
  9. Hope for the best





