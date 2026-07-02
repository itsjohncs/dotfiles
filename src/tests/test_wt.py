import os
import shutil
import subprocess
import time
from pathlib import Path

import pytest

WT_SH = Path(__file__).resolve().parent.parent / "bash_profile.d" / "wt.sh"
assert WT_SH.is_file()

BASH = shutil.which("bash")
FZF = shutil.which("fzf")

GIT_ENV = {
    **os.environ,
    "GIT_AUTHOR_NAME": "Test",
    "GIT_AUTHOR_EMAIL": "test@example.com",
    "GIT_COMMITTER_NAME": "Test",
    "GIT_COMMITTER_EMAIL": "test@example.com",
    "GIT_CONFIG_GLOBAL": "/dev/null",
    "GIT_CONFIG_SYSTEM": "/dev/null",
}


def bash_major_version():
    result = subprocess.run(
        [BASH, "-c", "echo ${BASH_VERSINFO[0]}"], capture_output=True, text=True
    )
    return int(result.stdout.strip())


pytestmark = pytest.mark.skipif(
    BASH is None or bash_major_version() < 4, reason="requires bash 4+"
)

needs_fzf = pytest.mark.skipif(FZF is None, reason="requires fzf")


def git(*args, cwd, **env):
    subprocess.run(
        ["git", *args],
        cwd=cwd,
        env={**GIT_ENV, **env},
        check=True,
        capture_output=True,
    )


def run_wt(script, cwd, env=None):
    """Source wt.sh and run a snippet, returning the CompletedProcess."""
    return subprocess.run(
        [BASH, "-c", f"source '{WT_SH}'\n{script}"],
        cwd=cwd,
        env=env or GIT_ENV,
        capture_output=True,
        text=True,
    )


@pytest.fixture
def repo(tmp_path):
    """A repo with two Claude-style worktrees: hippo (2 commits, recently
    active) and allen (no commits, older activity)."""
    root = tmp_path / "repo"
    root.mkdir()
    git("init", "-b", "main", cwd=root)
    # ws filters commit subjects to the configured author by default.
    git("config", "user.email", "test@example.com", cwd=root)
    (root / "README.md").write_text("hello\n")
    git("add", ".", cwd=root)
    # Backdate the initial commit so branches with no new commits (allen)
    # read as old, like a real worktree cut from an older main.
    week_ago = f"@{int(time.time()) - 7 * 86400} +0000"
    git(
        "commit",
        "-m",
        "initial commit",
        cwd=root,
        GIT_AUTHOR_DATE=week_ago,
        GIT_COMMITTER_DATE=week_ago,
    )

    worktrees = root / ".claude" / "worktrees"
    hippo = worktrees / "abstract-strolling-hippo"
    allen = worktrees / "breezy-rolling-allen"
    git(
        "worktree",
        "add",
        str(hippo),
        "-b",
        "worktree-abstract-strolling-hippo",
        cwd=root,
    )
    git("worktree", "add", str(allen), "-b", "worktree-breezy-rolling-allen", cwd=root)

    (hippo / "feature.txt").write_text("feature\n")
    git("add", ".", cwd=hippo)
    git("commit", "-m", "add hippo feature", cwd=hippo)
    (hippo / "fix.txt").write_text("fix\n")
    git("add", ".", cwd=hippo)
    git("commit", "-m", "fix hippo bug", cwd=hippo)

    # Recency is max(branch tip date, index mtime); pin index mtimes so
    # ordering is deterministic: hippo recent, allen old.
    now = time.time()
    os.utime(
        root / ".git" / "worktrees" / "abstract-strolling-hippo" / "index", (now, now)
    )
    old = now - 7 * 86400
    os.utime(root / ".git" / "worktrees" / "breezy-rolling-allen" / "index", (old, old))

    return root


def test_ws_newest_last_and_shows_subjects(repo):
    result = run_wt("ws", cwd=repo)
    assert result.returncode == 0
    out = result.stdout
    # Inverted output: oldest first, newest at the bottom near the prompt.
    assert out.index("breezy-rolling-allen") < out.index("abstract-strolling-hippo")
    assert "add hippo feature" in out
    assert "fix hippo bug" in out
    assert "(no commits vs main)" in out


def test_ws_marks_landed_commits_but_keeps_them_visible(repo):
    # Land hippo's first commit on main under a different sha; ws should
    # still show it, marked with a check, alongside the pending commit.
    # Pin a distinct committer date: with identical tree/parent/author and
    # a same-second timestamp, the cherry-pick reproduces the same sha.
    hour_ago = f"@{int(time.time()) - 3600} +0000"
    git(
        "cherry-pick",
        "worktree-abstract-strolling-hippo~1",
        cwd=repo,
        GIT_COMMITTER_DATE=hour_ago,
    )
    result = run_wt("ws", cwd=repo)
    assert result.returncode == 0
    lines = result.stdout.splitlines()
    landed = next(line for line in lines if "add hippo feature" in line)
    pending = next(line for line in lines if "fix hippo bug" in line)
    assert "✓" in landed
    assert "✓" not in pending


def other_author_commit(worktree, message):
    """Commit an empty change authored by someone else."""
    git(
        "commit",
        "--allow-empty",
        "-m",
        message,
        cwd=worktree,
        GIT_AUTHOR_NAME="Other",
        GIT_AUTHOR_EMAIL="other@example.com",
    )


def test_ws_hides_other_authors_commits_by_default(repo):
    hippo = repo / ".claude" / "worktrees" / "abstract-strolling-hippo"
    other_author_commit(hippo, "someone elses rebased commit")
    result = run_wt("ws", cwd=repo)
    assert result.returncode == 0
    assert "someone elses rebased commit" not in result.stdout
    assert "add hippo feature" in result.stdout


def test_ws_all_authors_flag_shows_everything(repo):
    hippo = repo / ".claude" / "worktrees" / "abstract-strolling-hippo"
    other_author_commit(hippo, "someone elses rebased commit")
    result = run_wt("ws -A", cwd=repo)
    assert result.returncode == 0
    assert "someone elses rebased commit" in result.stdout


def test_ws_notes_when_all_commits_are_by_others(repo):
    allen = repo / ".claude" / "worktrees" / "breezy-rolling-allen"
    other_author_commit(allen, "someone elses rebased commit")
    result = run_wt("ws", cwd=repo)
    assert result.returncode == 0
    assert "no commits by you; 1 by others" in result.stdout


def test_ws_recovers_prepared_commits_after_ff_merge(repo):
    # Fast-forwarding main to the branch leaves no sha difference at all;
    # the prepared commits should be recovered from the branch reflog.
    git("merge", "--ff-only", "worktree-abstract-strolling-hippo", cwd=repo)
    result = run_wt("ws", cwd=repo)
    assert result.returncode == 0
    lines = result.stdout.splitlines()
    landed = next(line for line in lines if "add hippo feature" in line)
    assert "✓" in landed
    assert "fix hippo bug" in result.stdout
    assert "(no commits vs main)" in result.stdout  # allen is unaffected


def test_ws_dirty_marker(repo):
    hippo = repo / ".claude" / "worktrees" / "abstract-strolling-hippo"
    (hippo / "uncommitted.txt").write_text("wip\n")
    result = run_wt("ws", cwd=repo)
    hippo_line = next(
        line
        for line in result.stdout.splitlines()
        if "abstract-strolling-hippo" in line
    )
    assert "*" in hippo_line


def test_ws_limit_keeps_newest_with_more_notice_on_top(repo):
    result = run_wt("ws -n 1", cwd=repo)
    assert result.returncode == 0
    out = result.stdout
    assert "abstract-strolling-hippo" in out
    assert "breezy-rolling-allen" not in out
    assert "1 more" in out
    assert out.index("1 more") < out.index("abstract-strolling-hippo")


def test_ws_handles_detached_worktree(repo):
    git(
        "worktree",
        "add",
        "--detach",
        str(repo / ".claude" / "worktrees" / "loose-end"),
        cwd=repo,
    )
    result = run_wt("ws -a", cwd=repo)
    assert result.returncode == 0
    assert "loose-end" in result.stdout


@needs_fzf
def test_wd_unique_match(repo):
    result = run_wt("wd hippo >/dev/null && pwd", cwd=repo)
    assert result.returncode == 0
    assert result.stdout.strip().endswith("abstract-strolling-hippo")


@needs_fzf
def test_wd_is_case_insensitive(repo):
    result = run_wt("wd HIPPO >/dev/null && pwd", cwd=repo)
    assert result.returncode == 0
    assert result.stdout.strip().endswith("abstract-strolling-hippo")


@needs_fzf
def test_wd_multi_token_match(repo):
    result = run_wt("wd rolling allen >/dev/null && pwd", cwd=repo)
    assert result.returncode == 0
    assert result.stdout.strip().endswith("breezy-rolling-allen")


@needs_fzf
def test_wd_subsequence_match(repo):
    # "bzy" is not a substring of any name, but fzf matches b..z..y in
    # "breezy" and nothing in the hippo worktree.
    result = run_wt("wd bzy >/dev/null && pwd", cwd=repo)
    assert result.returncode == 0
    assert result.stdout.strip().endswith("breezy-rolling-allen")


@needs_fzf
def test_wd_no_match_fails(repo):
    result = run_wt("wd zzzqqq", cwd=repo)
    assert result.returncode == 1
    assert "no worktree matches" in result.stderr


@needs_fzf
def test_wd_works_from_inside_another_worktree(repo):
    allen = repo / ".claude" / "worktrees" / "breezy-rolling-allen"
    result = run_wt("wd hippo >/dev/null && pwd", cwd=allen)
    assert result.returncode == 0
    assert result.stdout.strip().endswith("abstract-strolling-hippo")


def test_wd_without_fzf_says_how_to_install(repo):
    env = {**GIT_ENV, "PATH": "/usr/bin:/bin"}
    result = run_wt("wd hippo", cwd=repo, env=env)
    assert result.returncode == 1
    assert "brew install fzf" in result.stderr


def test_cw_forwards_to_claude_worktree(repo, tmp_path):
    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()
    fake_claude = fake_bin / "claude"
    fake_claude.write_text('#!/bin/sh\necho "claude $@"\n')
    fake_claude.chmod(0o755)
    env = {**GIT_ENV, "PATH": f"{fake_bin}:{os.environ['PATH']}"}
    result = run_wt("cw my-session", cwd=repo, env=env)
    assert result.returncode == 0
    assert result.stdout.strip() == "claude --worktree my-session"


def test_wp_returns_to_primary_checkout(repo):
    hippo = repo / ".claude" / "worktrees" / "abstract-strolling-hippo"
    result = run_wt("wp && pwd", cwd=hippo)
    assert result.returncode == 0
    assert Path(result.stdout.strip()) == repo


def test_wp_in_primary_checkout_stays_at_root(repo):
    result = run_wt("wp && pwd", cwd=repo)
    assert result.returncode == 0
    assert Path(result.stdout.strip()) == repo


def test_wp_outside_repo_fails(tmp_path):
    result = run_wt("wp", cwd=tmp_path)
    assert result.returncode == 1
    assert "not in a git repository" in result.stderr
