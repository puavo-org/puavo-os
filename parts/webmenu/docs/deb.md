# Debian package building

  1. Install `devscripts` package from apt
  1. Do source installation. See `docs/hacking.md`
  1. Checkout the debian branch
  1. Rebase to master
  1. Extract node.js binary tarball to `./nodejs`
  7. Update `debian/changelog` with `dch -i`
  8. Go to the parent dir and execute `./webmenu/builddeb.sh`
  9. Hope for the best



Node.js binary tarball extract

```
wget http://nodejs.org/dist/v0.8.14/node-v0.8.14-linux-x64.tar.gz
tar xzvf node-v0.8.14-linux-x64.tar.gz
rm node-v0.8.14-linux-x64.tar.gz 
mv node-v0.8.14-linux-x64 nodejs
```