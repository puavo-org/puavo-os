# puavo-pkg utility

import os.path


# Detect dynamic installed/not-installed states for every listed package
def detect_dynamic_package_states(root_dir, id_string):
    pkg_ids = str(id_string).split(' ') if id_string else []
    pkg_ids = filter(None, pkg_ids)
    pkg_ids = set(pkg_ids)

    states = {}

    for pkg_id in pkg_ids:
        states[pkg_id] = os.path.exists(os.path.join(root_dir, pkg_id))

    return states
