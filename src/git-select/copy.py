#!/usr/bin/env python3

import sys
import shlex
import subprocess
import argparse

from lib.ranges import Range
from lib.status import get_files_from_git_status


def parse_args(args):
    # The name of the function is used in error messages so we wrap it
    def index_or_range(*args, **kwargs):
        return Range.parse(*args, **kwargs)

    parser = argparse.ArgumentParser(
        description="Looks at the list of files displayed by git-status and, "
        "after skipping staged changes, copies the files at the given "
        "positions to your clipboard."
    )
    parser.add_argument(
        "-",
        "-l",
        "--list",
        action="store_true",
        help="Print the available choices and their indices.",
    )
    parser.add_argument(
        "ranges",
        metavar="INDEX_OR_RANGE",
        type=index_or_range,
        default=[(0, 0)],
        nargs="*",
        help="An index or inclusive range (ex: `1:`, `1:3`).",
    )
    return parser.parse_args(args)


def put_clipboard(text):
    with subprocess.Popen(
        ["pbcopy"], stdin=subprocess.PIPE, encoding="utf8"
    ) as process:
        process.communicate(text)
        if process.returncode != 0:
            raise RuntimeError("pbcopy gave non-zero status")


def main_copy_ranges(ranges):
    all_files = get_files_from_git_status()

    selected_files = []
    for range_ in ranges:
        try:
            selected_files.extend(range_.extract(all_files))
        except IndexError:
            print(f"Range out of bounds: {range_}")
            sys.exit(1)

    escaped_result = " ".join(shlex.quote(i) for i in selected_files)
    put_clipboard(escaped_result)

    print(f"Copied {escaped_result}")


def main_print_list():
    all_files = get_files_from_git_status()
    for index, path in enumerate(all_files):
        print(f"{index}. {path}")


def main(parsed_args):
    if parsed_args.list:
        main_print_list()
    elif parsed_args.ranges:
        main_copy_ranges(parsed_args.ranges)


if __name__ == "__main__":
    main(parse_args(sys.argv[1:]))
