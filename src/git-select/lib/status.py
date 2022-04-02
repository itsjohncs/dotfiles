import os
import subprocess
import re

_STATUS_RE = re.compile(r"^.[^ ] (?:.+ -> (?P<renamed_to>.+)|(?P<path>.+))$")


def get_files_from_git_status():
    git_root = subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], encoding="utf8"
    ).strip()

    result = []

    output = subprocess.check_output(["git", "status", "--porcelain"], encoding="utf8")
    for line in output.splitlines():
        match = _STATUS_RE.match(line)
        if match:
            path = match.group("renamed_to") or match.group("path")
            result.append(path.strip())

    return [os.path.relpath(os.path.join(git_root, i)) for i in result]
