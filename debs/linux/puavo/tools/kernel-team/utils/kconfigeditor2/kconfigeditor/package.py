import os

from .kconfig.menu import MenuEntryChoice, MenuEntryConfig
from .kconfig.config import File


class PackageFile(object):
    def __init__(self, key, kernelarch, featureset, file):
        self.keys = set(key)
        self.kernelarches = kernelarch and set((kernelarch,)) or set()
        self.featuresets = featureset and set((featureset,)) or set()
        self.file = file

    def add(self, key, kernelarch, featureset):
        self.keys.add(key)
        self.kernelarches.add(kernelarch)
        self.featuresets.add(featureset)

    @property
    def kernelarch(self):
        if len(self.kernelarches) == 1:
            return list(self.kernelarches)[0]

    @property
    def featureset(self):
        if len(self.featuresets) == 1:
            return list(self.featuresets)[0]


class Package(dict):
    def __init__(self, root):
        import imp

        data = imp.find_module('config', [os.path.join(root, 'debian', 'lib', 'python', 'debian_linux')])
        module = imp.load_module('config', *data)

        config_schema = {
            'image': {
                'configs': module.SchemaItemList(),
            },
        }

        self.config_root = os.path.join(root, "debian/config")
        self.config = module.ConfigCoreHierarchy(config_schema, (self.config_root, ))

        for filename, key, kernelarch, featureset in self._collect():
            if filename in self:
                data = self[filename]
                data.add(key, kernelarch, featureset)
            else:
                file = File(name=os.path.join(self.config_root, filename))
                self[filename] = PackageFile(key, kernelarch, featureset, file)

    def _collect(self):
        for filename in self._check_config('config'):
            yield filename, (), None, None

        for arch in self.config['base',]['arches']:
            for data in self._collect_arch(arch):
                yield data

    def _collect_arch(self, arch):
        config_entry = self.config.merge('base', arch)

        if not config_entry.get('enabled', True):
            return

        key = arch,
        kernelarch = config_entry.get('kernel-arch')

        for filename in self._check_config("%s/config" % arch, arch):
            yield filename, key, kernelarch, None

        for filename in self._check_config("kernelarch-%s/config" % kernelarch, arch):
            yield filename, key, kernelarch, None

        for featureset in self.config['base', arch].get('featuresets', ()):
            for data in self._collect_featureset(arch, kernelarch, featureset):
                yield data

    def _collect_featureset(self, arch, kernelarch, featureset):
        config_entry = self.config.merge('base', arch, featureset)

        if not config_entry.get('enabled', True):
            return

        key = arch, featureset

        for filename in self._check_config("featureset-%s/config" % featureset, None, featureset):
            yield filename, key, kernelarch, featureset
        for filename in self._check_config("%s/%s/config" % (arch, featureset), arch, featureset):
            yield filename, key, kernelarch, featureset

        for flavour in self.config['base', arch, featureset]['flavours']:
            for data in self._collect_flavour(arch, kernelarch, featureset, flavour):
                yield data

    def _collect_flavour(self, arch, kernelarch, featureset, flavour):
        config_entry = self.config.merge('base', arch, featureset, flavour)

        if not config_entry.get('enabled', True):
            return

        key = arch, featureset, flavour

        for filename in self._check_config("%s/config.%s" % (arch, flavour), arch, None, flavour):
            yield filename, key, kernelarch, featureset
        for filename in self._check_config("%s/%s/config.%s" % (arch, featureset, flavour), arch, featureset, flavour):
            yield filename, key, kernelarch, featureset

    def _check_config_default(self, f):
        if os.path.exists(os.path.join(self.config_root, f)):
            yield f

    def _check_config_files(self, files):
        for f in files:
            if os.path.exists(os.path.join(self.config_root, f)):
                yield f

    def _check_config(self, default, *entry_name):
        entry_real = ('image',) + entry_name
        entry = self.config.get(entry_real)
        if entry:
            configs = entry.get('configs')
            if configs:
                return self._check_config_files(configs)
        return self._check_config_default(default)

    @property
    def kernelarches(self):
        ret = set()
        for data in self.values():
            ret |= data.kernelarches
        return ret
