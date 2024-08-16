import pytest
from importlib.machinery import SourceFileLoader
import os

# Get the current file's directory
current_dir = os.path.dirname(os.path.abspath(__file__))

# Construct the path to the 'which' script
which_path = os.path.join(current_dir, "..", "scripts", "which")
assert os.path.isfile(which_path)

# Load the 'which' module
which = SourceFileLoader("which", which_path).load_module()


@pytest.mark.parametrize(
    "input_query, expected_output",
    [
        ("ls", "ls"),
        ("alias ls='ls -l'", "ls"),
        ("alias gc='git commit'", "git"),
        ("alias t='TIMCOL_NAME=t timcol'", "timcol"),
        ("alias background='long_running_command &'", "long_running_command"),
        ("not_an_alias", "not_an_alias"),
    ],
)
def test_get_command(input_query, expected_output):
    assert which.get_command(input_query) == expected_output


def test_get_command_empty_string():
    assert which.get_command("") == ""


@pytest.mark.parametrize(
    "complex_alias",
    [
        "alias complex='cd /path/to/dir && git status && echo \"Done\"'",
        'alias multi=\'echo "Start"; ls -l; echo "End"\'',
        "alias pipe='cat file.txt | grep pattern | sort'",
        "alias conditional='if [ -f file.txt ]; then cat file.txt; else echo \"Not found\"; fi'",
        "alias subshell='(cd /tmp && ls)'",
    ],
)
def test_get_command_complex_alias(complex_alias):
    with pytest.raises(ValueError, match="Complex aliases are not supported"):
        which.get_command(complex_alias)


def test_get_command_simple_alias_with_options():
    simple_alias = "alias ls='ls -la'"
    assert which.get_command(simple_alias) == "ls"
