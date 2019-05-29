# puavo-pkg utility

import os.path


# Detect installed/not-installed states for every listed package
def detect_package_states(root_dir, id_string):
    pkg_data = {}

    pkg_ids = str(id_string).split(' ') if id_string else []
    pkg_ids = filter(None, pkg_ids)
    pkg_ids = set(pkg_ids)

    for pkg_id in pkg_ids:
        if os.path.exists(os.path.join(root_dir, pkg_id)):
            pkg_data[pkg_id] = True
        else:
            pkg_data[pkg_id] = False

    return pkg_data
