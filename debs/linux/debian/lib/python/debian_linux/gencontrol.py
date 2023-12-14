from __future__ import annotations

import os
import pathlib
import re
import typing
from collections import OrderedDict

from .debian import Changelog, PackageArchitecture, \
    PackageBuildRestrictFormula, PackageBuildRestrictList, \
    PackageBuildRestrictTerm, PackageRelation, Version
from .utils import Templates


class PackagesList(OrderedDict):
    def append(self, package):
        self[package['Package']] = package

    def extend(self, packages):
        for package in packages:
            self[package['Package']] = package

    def setdefault(self, package):
        return super().setdefault(package['Package'], package)


class Makefile:
    def __init__(self):
        self.rules = {}

    def add_cmds(self, name, cmds):
        rule = self.rules.setdefault(name, MakefileRule(name))
        rule.add_cmds(MakefileRuleCmdsSimple(cmds))

    def add_deps(self, name, deps):
        rule = self.rules.setdefault(name, MakefileRule(name))
        rule.add_deps(deps)

        for i in deps:
            self.rules.setdefault(i, MakefileRule(i))

    def add_rules(self, name, target, makeflags, packages=set(), packages_extra=set()):
        rule = self.rules.setdefault(name, MakefileRule(name))
        rule.add_cmds(MakefileRuleCmdsRules(target, makeflags, packages, packages_extra))

    def write(self, out):
        out.write('''\
.NOTPARALLEL:
.PHONY:
packages_enabled := $(shell dh_listpackages)
define if_package
$(if $(filter $(1),$(packages_enabled)),$(2))
endef
''')
        for k, rule in sorted(self.rules.items()):
            rule.write(out)


class MakefileRule:
    def __init__(self, name):
        self.name = name
        self.cmds = []
        self.deps = set()

    def add_cmds(self, cmds):
        self.cmds.append(cmds)

    def add_deps(self, deps):
        assert type(deps) is list
        self.deps.update(deps)

    def write(self, out):
        if self.cmds:
            out.write(f'{self.name}:{" ".join(sorted(self.deps))}\n')
            for c in self.cmds:
                c.write(out)
        else:
            out.write(f'{self.name}:{" ".join(sorted(self.deps))}\n')


class MakefileRuleCmdsRules:
    def __init__(self, target, makeflags, packages, packages_extra):
        self.target = target
        self.makeflags = makeflags.copy()
        self.packages = packages
        self.packages_extra = packages_extra

        packages_all = packages | packages_extra

        if packages_all:
            if len(packages_all) == 1:
                package_name = list(packages_all)[0]
                self.makeflags['PACKAGE_NAME'] = package_name
                self.makeflags['DESTDIR'] = f'$(CURDIR)/debian/{package_name}'
            else:
                self.makeflags['DESTDIR'] = '$(CURDIR)/debian/tmp'

            self.makeflags['DH_OPTIONS'] = ' '.join(f'-p{i}' for i in sorted(packages_all))

    def write(self, out):
        cmd = f'$(MAKE) -f debian/rules.real {self.target} {self.makeflags}'
        if self.packages:
            out.write(f'\t$(call if_package, {" ".join(sorted(self.packages))}, {cmd})\n')
        else:
            out.write(f'\t{cmd}\n')


class MakefileRuleCmdsSimple:
    def __init__(self, cmds):
        self.cmds = cmds

    def write(self, out):
        for i in self.cmds:
            out.write(f'\t{i}\n')


class MakeFlags(dict):
    def __str__(self):
        return ' '.join("%s='%s'" % i for i in sorted(self.items()))

    def copy(self):
        return self.__class__(super(MakeFlags, self).copy())


class PackagesBundle:
    name: typing.Optional[str]
    templates: Templates
    base: pathlib.Path
    makefile: Makefile
    packages: PackagesList

    def __init__(
            self,
            name: typing.Optional[str],
            templates: Templates,
            base: pathlib.Path = pathlib.Path('debian'),
    ) -> None:
        self.name = name
        self.templates = templates
        self.base = base
        self.makefile = Makefile()
        self.packages = PackagesList()

    def add(
            self,
            pkgid: str,
            ruleid: tuple[str],
            makeflags: MakeFlags,
            replace: dict[str, str],
            *,
            arch: str = None,
            check_packages: bool = True,
    ) -> list[typing.Any]:
        ret = []
        for raw_package in self.templates.get_control(f'{pkgid}.control', replace):
            package = self.packages.setdefault(raw_package)
            package_name = package['Package']
            ret.append(package)

            package.meta.setdefault('rules-ruleids', {})[ruleid] = makeflags
            if arch:
                package.meta.setdefault('architectures', PackageArchitecture()).add(arch)
            package.meta['rules-check-packages'] = check_packages

            for name in (
                    'bug-presubj',
                    'lintian-overrides',
                    'maintscript',
                    'postinst',
                    'postrm',
                    'preinst',
                    'prerm',
            ):
                try:
                    template = self.templates.get(f'{pkgid}.{name}',
                                                  replace | {'package': package_name})
                except KeyError:
                    pass
                else:
                    with self.path(f'{package_name}.{name}').open('w') as f:
                        f.write(template)
                        os.chmod(f.fileno(),
                                 self.templates.get_mode(f'{pkgid}.{name}') & 0o777)

        return ret

    def add_packages(
            self,
            packages: PackagesList,
            ruleid: tuple[str],
            makeflags: MakeFlags,
            *,
            arch: str = None,
            check_packages: bool = True,
    ) -> None:
        for package in packages:
            package = self.packages.setdefault(package)
            package.meta.setdefault('rules-ruleids', {})[ruleid] = makeflags
            if arch:
                package.meta.setdefault('architectures', PackageArchitecture()).add(arch)
            package.meta['rules-check-packages'] = check_packages

    def path(self, name) -> pathlib.Path:
        if self.name:
            raise RuntimeError
            return self.base / f'debian/generated.{self.name}/{name}'
        return self.base / name

    @property
    def path_control(self) -> pathlib.Path:
        return self.path('control')

    @property
    def path_makefile(self) -> pathlib.Path:
        return self.path('rules.gen')

    @staticmethod
    def __ruleid_deps(ruleid: tuple[str], name: str) -> typing.Iterator[tuple[str, str]]:
        """
        Generate all the rules dependencies.
        ```
        build: build_a
        build_a: build_a_b
        build_a_b: build_a_b_image
        ```
        """
        r = ruleid + (name, )
        yield (
            '',
            '_' + '_'.join(r[:1]),
        )
        for i in range(1, len(r)):
            yield (
                '_' + '_'.join(r[:i]),
                '_' + '_'.join(r[:i + 1]),
            )

    def extract_makefile(self) -> None:
        targets = {}

        for package_name, package in self.packages.items():
            target_name = package.meta.get('rules-target')
            ruleids = package.meta.get('rules-ruleids')
            makeflags = MakeFlags({
                # Requires Python 3.9+
                k.removeprefix('rules-makeflags-').upper(): v
                for (k, v) in package.meta.items() if k.startswith('rules-makeflags-')
            })

            if ruleids:
                arches = package.meta.get('architectures')
                if arches:
                    package['Architecture'] = arches
                else:
                    arches = package.get('Architecture')

                if target_name:
                    for ruleid, makeflags_package in ruleids.items():
                        target_key = frozenset(
                            [target_name, ruleid]
                            + [f'{k}_{v}' for (k, v) in makeflags.items()]
                        )
                        target = targets.setdefault(
                            target_key,
                            {
                                'name': target_name,
                                'ruleid': ruleid,
                            },
                        )

                        if package.meta['rules-check-packages']:
                            target.setdefault('packages', set()).add(package_name)
                        else:
                            target.setdefault('packages_extra', set()).add(package_name)
                        makeflags_package = makeflags_package.copy()
                        makeflags_package.update(makeflags)
                        target['makeflags'] = makeflags_package

                        if arches == set(['all']):
                            target['type'] = 'indep'
                        else:
                            target['type'] = 'arch'

        for target in targets.values():
            name = target['name']
            ruleid = target['ruleid']
            packages = target.get('packages', set())
            packages_extra = target.get('packages_extra', set())
            makeflags = target['makeflags']
            ttype = target['type']

            rule = '_'.join(ruleid)
            self.makefile.add_rules(f'setup_{rule}_{name}',
                                    f'setup_{name}', makeflags, packages, packages_extra)
            self.makefile.add_rules(f'build-{ttype}_{rule}_{name}',
                                    f'build_{name}', makeflags, packages, packages_extra)
            self.makefile.add_rules(f'binary-{ttype}_{rule}_{name}',
                                    f'binary_{name}', makeflags, packages, packages_extra)

            for i, j in self.__ruleid_deps(ruleid, name):
                self.makefile.add_deps(f'setup{i}',
                                       [f'setup{j}'])
                self.makefile.add_deps(f'build-{ttype}{i}',
                                       [f'build-{ttype}{j}'])
                self.makefile.add_deps(f'binary-{ttype}{i}',
                                       [f'binary-{ttype}{j}'])

    def merge_build_depends(self):
        # Merge Build-Depends pseudo-fields from binary packages into the
        # source package
        source = self.packages["source"]
        arch_all = PackageArchitecture("all")
        for name, package in self.packages.items():
            if name == "source":
                continue
            dep = package.get("Build-Depends")
            if not dep:
                continue
            del package["Build-Depends"]
            for group in dep:
                for item in group:
                    if package["Architecture"] != arch_all and not item.arches:
                        item.arches = sorted(package["Architecture"])
                    if package.get("Build-Profiles") and not item.restrictions:
                        item.restrictions = package["Build-Profiles"]
            if package["Architecture"] == arch_all:
                dep_type = "Build-Depends-Indep"
            else:
                dep_type = "Build-Depends-Arch"
            if dep_type not in source:
                source[dep_type] = PackageRelation()
            source[dep_type].extend(dep)

    def write(self) -> None:
        self.write_control()
        self.write_makefile()

    def write_control(self) -> None:
        with self.path_control.open('w', encoding='utf-8') as f:
            self.write_rfc822(f, self.packages.values())

    def write_makefile(self) -> None:
        with self.path_makefile.open('w', encoding='utf-8') as f:
            self.makefile.write(f)

    def write_rfc822(self, f: typing.TextIO, entries: typing.Iterable) -> None:
        for entry in entries:
            for key, value in entry.items():
                if value:
                    f.write(u"%s: %s\n" % (key, value))
            f.write('\n')


def iter_featuresets(config):
    for featureset in config['base', ]['featuresets']:
        if config.merge('base', None, featureset).get('enabled', True):
            yield featureset


def iter_arches(config):
    return iter(config['base', ]['arches'])


def iter_arch_featuresets(config, arch):
    for featureset in config['base', arch].get('featuresets', []):
        if config.merge('base', arch, featureset).get('enabled', True):
            yield featureset


def iter_flavours(config, arch, featureset):
    return iter(config['base', arch, featureset]['flavours'])


class Gencontrol(object):
    def __init__(self, config, templates, version=Version):
        self.config, self.templates = config, templates
        self.changelog = Changelog(version=version)
        self.vars = {}
        self.bundles = {None: PackagesBundle(None, templates)}
        # TODO: Remove after all references are gone
        self.packages = self.bundle.packages
        self.makefile = self.bundle.makefile

    @property
    def bundle(self) -> PackagesBundle:
        return self.bundles[None]

    def __call__(self):
        self.do_source()
        self.do_main()
        self.do_extra()

        self.write()

    def do_source(self):
        source = self.templates.get_source_control("source.control", self.vars)[0]
        if not source.get('Source'):
            source['Source'] = self.changelog[0].source
        self.packages['source'] = source

    def do_main(self):
        vars = self.vars.copy()

        makeflags = MakeFlags()
        extra = {}

        self.do_main_setup(vars, makeflags, extra)
        self.do_main_makefile(makeflags, extra)
        self.do_main_packages(vars, makeflags, extra)
        self.do_main_recurse(vars, makeflags, extra)

    def do_main_setup(self, vars, makeflags, extra):
        pass

    def do_main_makefile(self, makeflags, extra):
        pass

    def do_main_packages(self, vars, makeflags, extra):
        pass

    def do_main_recurse(self, vars, makeflags, extra):
        for featureset in iter_featuresets(self.config):
            self.do_indep_featureset(featureset,
                                     vars.copy(), makeflags.copy(), extra)
        for arch in iter_arches(self.config):
            self.do_arch(arch, vars.copy(),
                         makeflags.copy(), extra)

    def do_extra(self):
        try:
            packages_extra = self.templates.get_control("extra.control", self.vars)
        except KeyError:
            return

        extra_arches = {}
        for package in packages_extra:
            arches = package['Architecture']
            for arch in arches:
                i = extra_arches.get(arch, [])
                i.append(package)
                extra_arches[arch] = i
        for arch in sorted(extra_arches.keys()):
            self.bundle.add_packages(packages_extra, (arch, 'real'),
                                     MakeFlags(), check_packages=False)

    def do_indep_featureset(self, featureset, vars,
                            makeflags, extra):
        vars['localversion'] = ''
        if featureset != 'none':
            vars['localversion'] = '-' + featureset

        self.do_indep_featureset_setup(vars, makeflags, featureset, extra)
        self.do_indep_featureset_makefile(featureset, makeflags,
                                          extra)
        self.do_indep_featureset_packages(featureset,
                                          vars, makeflags, extra)

    def do_indep_featureset_setup(self, vars, makeflags, featureset, extra):
        pass

    def do_indep_featureset_makefile(self, featureset, makeflags,
                                     extra):
        makeflags['FEATURESET'] = featureset

    def do_indep_featureset_packages(self, featureset, vars, makeflags, extra):
        pass

    def do_arch(self, arch, vars, makeflags, extra):
        vars['arch'] = arch

        self.do_arch_setup(vars, makeflags, arch, extra)
        self.do_arch_makefile(arch, makeflags, extra)
        self.do_arch_packages(arch, vars, makeflags, extra)
        self.do_arch_recurse(arch, vars, makeflags, extra)

    def do_arch_setup(self, vars, makeflags, arch, extra):
        pass

    def do_arch_makefile(self, arch, makeflags, extra):
        makeflags['ARCH'] = arch

    def do_arch_packages(self, arch, vars, makeflags,
                         extra):
        pass

    def do_arch_recurse(self, arch, vars, makeflags,
                        extra):
        for featureset in iter_arch_featuresets(self.config, arch):
            self.do_featureset(arch, featureset,
                               vars.copy(), makeflags.copy(), extra)

    def do_featureset(self, arch, featureset, vars,
                      makeflags, extra):
        vars['localversion'] = ''
        if featureset != 'none':
            vars['localversion'] = '-' + featureset

        self.do_featureset_setup(vars, makeflags, arch, featureset, extra)
        self.do_featureset_makefile(arch, featureset, makeflags, extra)
        self.do_featureset_packages(arch, featureset, vars, makeflags, extra)
        self.do_featureset_recurse(arch, featureset, vars, makeflags, extra)

    def do_featureset_setup(self, vars, makeflags, arch, featureset, extra):
        pass

    def do_featureset_makefile(self, arch, featureset, makeflags,
                               extra):
        makeflags['FEATURESET'] = featureset

    def do_featureset_packages(self, arch, featureset, vars, makeflags, extra):
        pass

    def do_featureset_recurse(self, arch, featureset, vars, makeflags, extra):
        for flavour in iter_flavours(self.config, arch, featureset):
            self.do_flavour(arch, featureset, flavour,
                            vars.copy(), makeflags.copy(), extra)

    def do_flavour(self, arch, featureset, flavour, vars,
                   makeflags, extra):
        vars['localversion'] += '-' + flavour

        self.do_flavour_setup(vars, makeflags, arch, featureset, flavour,
                              extra)
        self.do_flavour_makefile(arch, featureset, flavour, makeflags, extra)
        self.do_flavour_packages(arch, featureset, flavour,
                                 vars, makeflags, extra)

    def do_flavour_setup(self, vars, makeflags, arch, featureset, flavour,
                         extra):
        for i in (
            ('kernel-arch', 'KERNEL_ARCH'),
            ('localversion', 'LOCALVERSION'),
        ):
            if i[0] in vars:
                makeflags[i[1]] = vars[i[0]]

    def do_flavour_makefile(self, arch, featureset, flavour,
                            makeflags, extra):
        makeflags['FLAVOUR'] = flavour

    def do_flavour_packages(self, arch, featureset,
                            flavour, vars, makeflags, extra):
        pass

    def substitute(self, s, vars):
        if isinstance(s, (list, tuple)):
            return [self.substitute(i, vars) for i in s]

        def subst(match):
            return vars[match.group(1)]

        return re.sub(r'@([-_a-z0-9]+)@', subst, str(s))

    def write(self):
        for bundle in self.bundles.values():
            bundle.merge_build_depends()
            bundle.extract_makefile()
            bundle.write()

    # TODO: Remove
    def write_control(self, name='debian/control'):
        self.write_rfc822(open(name, 'w', encoding='utf-8'), self.packages.values())

    # TODO: Remove
    def write_makefile(self, name='debian/rules.gen'):
        f = open(name, 'w')
        self.makefile.write(f)
        f.close()

    # TODO: Remove
    def write_rfc822(self, f, list):
        for entry in list:
            for key, value in entry.items():
                f.write(u"%s: %s\n" % (key, value))
            f.write('\n')


def merge_packages(packages, new, arch):
    for new_package in new:
        name = new_package['Package']
        if name in packages:
            package = packages.get(name)
            package['Architecture'].add(arch)

            for field in ('Depends', 'Provides', 'Suggests', 'Recommends',
                          'Conflicts'):
                if field in new_package:
                    if field in package:
                        v = package[field]
                        v.extend(new_package[field])
                    else:
                        package[field] = new_package[field]

        else:
            new_package['Architecture'] = arch
            packages.append(new_package)


def add_package_build_restriction(package, term):
    if not isinstance(term, PackageBuildRestrictTerm):
        term = PackageBuildRestrictTerm(term)
    old_form = package['Build-Profiles']
    new_form = PackageBuildRestrictFormula()
    for old_list in old_form:
        new_list = PackageBuildRestrictList(list(old_list) + [term])
        new_form.add(new_list)
    package['Build-Profiles'] = new_form
