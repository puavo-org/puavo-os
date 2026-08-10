#!/usr/bin/env python3

# Standard library imports
import os
import os.path
import sys

# Third-party imports
import toml


def _main() -> int:
    for dirpath, dirnames, filenames in os.walk("debian/config"):
        for filename in filenames:
            if filename != "defines.toml":
                continue
            defines_filepath = os.path.join(dirpath, filename)
            defines = toml.load(defines_filepath)

            for release in defines.get("debianrelease", []):
                if release.get("name_regex") == "bookworm(-security)?":
                  release["revision_regex"] = (
                      r"\d+(\.\d+)?"
                      r"(\+deb13u\d+)?"
                      r"~deb12u\d+"
                      r"(\+puavo\d+(\+buildonce)?)?"
                  )

            # We don't need any special feature sets.
            defines["featureset"] = [{"name": "none"}]

            with open(defines_filepath, "w", encoding="utf-8") as defines_file:
                toml.dump(defines, defines_file)

    return 0


if __name__ == "__main__":
    sys.exit(_main())
