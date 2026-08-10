import importlib
import os
import pathlib
import sys

from .kconfig.menu import MenuEntryChoice, MenuEntryConfig
from .kconfig.config import File


class PackageFile(object):
    def __init__(self, kernelarch, featureset, file):
        self.kernelarches = kernelarch and set((kernelarch,)) or set()
        self.featuresets = featureset and set((featureset,)) or set()
        self.file = file

    def add(self, kernelarch, featureset):
        if kernelarch:
            self.kernelarches.add(kernelarch)
        if featureset:
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
        python_root = os.path.join(root, 'debian', 'lib', 'python')
        if not python_root in sys.path:
            sys.path.insert(0, python_root)

        config_root = os.path.join(root, "debian/config")

        try:
            PackageConfigV2(config_root)(self)
        except ImportError:
            PackageConfigV1(config_root)(self)

    @property
    def kernelarches(self):
        ret = set()
        for data in self.values():
            ret |= data.kernelarches
        return ret


class PackageConfigV1:
    def __init__(self, config_root):
        module = importlib.import_module('debian_linux.config')

        config_schema = {
            'image': {
                'configs': module.SchemaItemList(),
            },
        }

        self.config_root = config_root
        self.config = module.ConfigCoreHierarchy(config_schema, (self.config_root, ))

    def __call__(self, out):
        for filename, kernelarch, featureset in self._collect():
            if filename in out:
                data = out[filename]
                data.add(kernelarch, featureset)
            else:
                file = File(name=os.path.join(self.config_root, filename))
                out[filename] = PackageFile(kernelarch, featureset, file)

    def _collect(self):
        for filename in self._check_config('config'):
            yield filename, None, None

        for arch in self.config['base',]['arches']:
            for data in self._collect_arch(arch):
                yield data

    def _collect_arch(self, arch):
        config_entry = self.config.merge('base', arch)

        if not config_entry.get('enabled', True):
            return

        kernelarch = config_entry.get('kernel-arch')

        for filename in self._check_config("%s/config" % arch, arch):
            yield filename, kernelarch, None

        for filename in self._check_config("kernelarch-%s/config" % kernelarch, arch):
            yield filename, kernelarch, None

        for featureset in self.config['base', arch].get('featuresets', ()):
            for data in self._collect_featureset(arch, kernelarch, featureset):
                yield data

    def _collect_featureset(self, arch, kernelarch, featureset):
        config_entry = self.config.merge('base', arch, featureset)

        if not config_entry.get('enabled', True):
            return

        for filename in self._check_config("featureset-%s/config" % featureset, None, featureset):
            yield filename, kernelarch, featureset
        for filename in self._check_config("%s/%s/config" % (arch, featureset), arch, featureset):
            yield filename, kernelarch, featureset

        for flavour in self.config['base', arch, featureset]['flavours']:
            for data in self._collect_flavour(arch, kernelarch, featureset, flavour):
                yield data

    def _collect_flavour(self, arch, kernelarch, featureset, flavour):
        config_entry = self.config.merge('base', arch, featureset, flavour)

        if not config_entry.get('enabled', True):
            return

        for filename in self._check_config("%s/config.%s" % (arch, flavour), arch, None, flavour):
            yield filename, kernelarch, featureset
        for filename in self._check_config("%s/%s/config.%s" % (arch, featureset, flavour), arch, featureset, flavour):
            yield filename, kernelarch, featureset

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


class PackageConfigV2:
    def __init__(self, config_root):
        module = importlib.import_module('debian_linux.config_v2')

        self.config_root = pathlib.Path(config_root)
        self.config = module.Config.read_orig([self.config_root])

    def __call__(self, out):
        for filename, kernelarch, featureset in self._collect(self.config.merged):
            if (f := self.config_root / filename).exists():
                if filename in out:
                    data = out[filename]
                    data.add(kernelarch, featureset)
                else:
                    file = File(name=str(f))
                    out[filename] = PackageFile(kernelarch, featureset, file)

    def _collect(self, config):
        for featureset in config.root_featuresets:
            yield from self._collect_config(featureset.build, None, None)

        for kernelarch in config.kernelarchs:
            yield from self._collect_config(kernelarch.build, kernelarch.name, None)

            for debianarch in kernelarch.debianarchs:
                yield from self._collect_config(debianarch.build, kernelarch.name, None)

                for featureset in debianarch.featuresets:
                    yield from self._collect_config(featureset.build, kernelarch.name, featureset.name)

                    for flavour in featureset.flavours:
                        yield from self._collect_config(flavour.build, kernelarch.name, featureset.name)

    def _collect_config(self, build, *args):
        for c in build.config + build.config_default:
            yield str(c), *args
