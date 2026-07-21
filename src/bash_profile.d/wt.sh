#!/usr/bin/env bash

# Tools for working with git worktrees (mostly ones Claude Code creates under
# .claude/worktrees/). Requires bash 4+; wd requires fzf.
#
#   ws  — list linked worktrees by recency (newest last, nearest the prompt)
#   wd  — cd into a worktree, fuzzy-matched with fzf (wd .. pops back to the
#         primary checkout; pd without args also climbs out of a worktree)
#   cw  — start a new Claude Code session in a fresh worktree

# Colors used by ws and its render helper (set per-call in ws).
__wt_bold=""
__wt_dim=""
__wt_yellow=""
__wt_reset=""

# Emit one line per linked worktree, most recently active first:
#   <epoch>\t<path>\t<branch>\t<sha>
# "Active" is the newer of the branch tip's commit date and the worktree's
# index mtime (which catches uncommitted work).
function __wt_entries {
    local porcelain
    porcelain=$(command git worktree list --porcelain 2>/dev/null) || {
        echo "wt: not in a git repository" >&2
        return 1
    }

    local -A tip_epoch=()
    local epoch ref
    while read -r epoch ref; do
        [[ -n $ref ]] && tip_epoch[$ref]=$epoch
    done < <(command git for-each-ref --format='%(committerdate:unix) %(refname:short)' refs/heads)

    local line path="" branch="" sha="" primary_seen=0
    local -a paths=() branches=() shas=()
    while IFS= read -r line; do
        case $line in
        worktree\ *) path=${line#worktree } ;;
        HEAD\ *) sha=${line#HEAD } ;;
        branch\ refs/heads/*) branch=${line#branch refs/heads/} ;;
        detached) branch="(detached)" ;;
        "")
            if [[ -n $path ]]; then
                if ((primary_seen)); then
                    paths+=("$path")
                    branches+=("$branch")
                    shas+=("$sha")
                else
                    primary_seen=1
                fi
            fi
            path="" branch="" sha=""
            ;;
        esac
    done <<<"$porcelain"$'\n'

    ((${#paths[@]})) || return 0

    # Index mtimes in a single stat invocation — one stat per worktree is the
    # slow part with ~100 worktrees.
    local -a mtimes=() specs=() files=()
    local i gitdir_line f
    for i in "${!paths[@]}"; do
        mtimes[i]=0
        if IFS= read -r gitdir_line 2>/dev/null <"${paths[$i]}/.git"; then
            f="${gitdir_line#gitdir: }/index"
            if [[ -f $f ]]; then
                specs+=("$i")
                files+=("$f")
            fi
        fi
    done
    if ((${#files[@]})); then
        # GNU syntax first: GNU stat treats -f as "filesystem status" and
        # exits 0 with garbage, so it must not be the fallback. BSD stat
        # fails fast on -c.
        local out
        out=$(stat -c %Y "${files[@]}" 2>/dev/null) ||
            out=$(stat -f %m "${files[@]}" 2>/dev/null) ||
            out=""
        local -a stat_lines=()
        [[ -n $out ]] && while IFS= read -r line; do stat_lines+=("$line"); done <<<"$out"
        if ((${#stat_lines[@]} == ${#specs[@]})); then
            local j
            for j in "${!specs[@]}"; do
                [[ ${stat_lines[$j]} =~ ^[0-9]+$ ]] && mtimes[specs[j]]=${stat_lines[$j]}
            done
        fi
    fi

    local -a rows=()
    for i in "${!paths[@]}"; do
        epoch=${tip_epoch[${branches[$i]}]:-0}
        ((mtimes[i] > epoch)) && epoch=${mtimes[i]}
        rows+=("$epoch"$'\t'"${paths[$i]}"$'\t'"${branches[$i]}"$'\t'"${shas[$i]}")
    done
    printf '%s\n' "${rows[@]}" | sort -t$'\t' -k1,1 -rn
}

# Print the path of the primary checkout (parent repo).
function __wt_primary_path {
    local common
    common=$(command git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
    dirname "$common"
}

# Prefer the local default branch: Claude Code cuts worktrees from local
# main, and origin/HEAD may lag it (showing main's commits as "unique").
function __wt_base_ref {
    local ref
    for ref in main master; do
        if command git show-ref --verify --quiet "refs/heads/$ref"; then
            echo "$ref"
            return
        fi
    done
    if ref=$(command git rev-parse --abbrev-ref origin/HEAD 2>/dev/null); then
        echo "$ref"
        return
    fi
    return 1
}

function __wt_reltime {
    local now=${EPOCHSECONDS:-$(date +%s)}
    local s=$((now - $1))
    ((s < 0)) && s=0
    if ((s < 60)); then
        echo "now"
    elif ((s < 3600)); then
        echo "$((s / 60))m ago"
    elif ((s < 86400)); then
        echo "$((s / 3600))h ago"
    elif ((s < 604800)); then
        echo "$((s / 86400))d ago"
    else
        echo "$((s / 604800))w ago"
    fi
}

# Render one ws entry (header line + commit subjects) to stdout.
function __ws_render_entry {
    local epoch=$1 path=$2 branch=$3 sha=$4 base=$5 author=$6
    local name=${path##*/}
    local rel
    rel=$(__wt_reltime "$epoch")

    local rev=$branch
    [[ $branch == "(detached)" ]] && rev=$sha

    local dirty=""
    # --no-optional-locks: a plain status refreshes the index, which would
    # bump the mtime that ws itself sorts by — listing must not reorder.
    if [[ -n $(command git -C "$path" --no-optional-locks status --porcelain 2>/dev/null | head -1) ]]; then
        dirty=" ${__wt_yellow}*${__wt_reset}"
    fi

    local extra=""
    if [[ $branch != "worktree-$name" ]]; then
        extra="  ${__wt_dim}[$branch]${__wt_reset}"
    fi

    printf '%s%-*s%s  %s%7s%s%s%s\n' "$__wt_bold" 44 "$name" "$__wt_reset" \
        "$__wt_dim" "$rel" "$__wt_reset" "$dirty" "$extra"

    if [[ -n $base ]]; then
        # --cherry-mark flags commits whose patch already landed on the base
        # branch under a different sha (%m: '=' landed, '>' pending), so the
        # work prepared here stays visible after it merges. The author filter
        # hides upstream commits duplicated onto the branch by rebases.
        local -a afilter=()
        [[ -n $author ]] && afilter=(--author="$author")
        local count line mark subject
        count=$(command git rev-list --count --right-only --no-merges "${afilter[@]}" "$base...$rev" 2>/dev/null) || count=0
        [[ $count =~ ^[0-9]+$ ]] || count=0
        if ((count > 0)); then
            while IFS= read -r line; do
                mark=${line%% *}
                subject=${line#* }
                if [[ $mark == "=" ]]; then
                    printf '    %s✓ %s%s\n' "$__wt_dim" "$subject" "$__wt_reset"
                else
                    printf '    %s\n' "$subject"
                fi
            done < <(command git log --max-count=3 --cherry-mark --right-only --no-merges "${afilter[@]}" --format='%m %s' "$base...$rev" 2>/dev/null)
            ((count > 3)) && printf '    %s… %d more commits%s\n' "$__wt_dim" "$((count - 3))" "$__wt_reset"
        else
            local total=0
            if [[ -n $author ]]; then
                total=$(command git rev-list --count --right-only --no-merges "$base...$rev" 2>/dev/null) || total=0
                [[ $total =~ ^[0-9]+$ ]] || total=0
            fi
            # An ff-merged branch has NO sha difference vs base, so recover
            # what was prepared here from the branch reflog's commit entries.
            local -a merged=()
            if ((total == 0)) && [[ $branch != "(detached)" ]] &&
                command git merge-base --is-ancestor "$rev" "$base" 2>/dev/null; then
                while IFS= read -r line; do
                    merged+=("$line")
                done < <(command git log -g --format='%gs' "$rev" 2>/dev/null |
                    sed -n 's/^commit[^:]*: //p' | awk '!seen[$0]++')
            fi
            if ((${#merged[@]})); then
                local m=0
                for line in "${merged[@]}"; do
                    ((m >= 3)) && break
                    printf '    %s✓ %s%s\n' "$__wt_dim" "$line" "$__wt_reset"
                    m=$((m + 1))
                done
                ((${#merged[@]} > 3)) && printf '    %s… %d more commits%s\n' "$__wt_dim" "$((${#merged[@]} - 3))" "$__wt_reset"
            elif ((total > 0)); then
                printf '    %s(no commits by you; %d by others — ws -A)%s\n' "$__wt_dim" "$total" "$__wt_reset"
            else
                printf '    %s(no commits vs %s)%s\n' "$__wt_dim" "$base" "$__wt_reset"
            fi
        fi
    fi
}

## ws: List git worktrees by recency (newest last), with commits that differ from the base branch
# Usage: ws [-a] [-n N] [-A]
# Default: 5 most recent worktrees, commits by you only (rebases duplicate
# other people's commits onto a branch). -a shows all worktrees; -A shows
# commits by all authors.
function ws {
    local limit=5 all=0 all_authors=0 opt OPTIND=1
    while getopts ":an:A" opt; do
        case $opt in
        a) all=1 ;;
        n) limit=$OPTARG ;;
        A) all_authors=1 ;;
        *)
            echo "Usage: ws [-a] [-n N] [-A]" >&2
            return 2
            ;;
        esac
    done

    local author=""
    ((all_authors == 0)) && author=$(command git config user.email 2>/dev/null)

    local entries
    entries=$(__wt_entries) || return 1
    if [[ -z $entries ]]; then
        echo "ws: no linked worktrees"
        return 0
    fi

    local base
    base=$(__wt_base_ref) || base=""

    __wt_bold="" __wt_dim="" __wt_yellow="" __wt_reset=""
    if [[ -t 1 ]]; then
        __wt_bold=$'\e[1m' __wt_dim=$'\e[2m' __wt_yellow=$'\e[33m' __wt_reset=$'\e[0m'
    fi

    local -a rows=()
    local line
    while IFS= read -r line; do rows+=("$line"); done <<<"$entries"
    local total=${#rows[@]} n=${#rows[@]}
    ((all == 0 && n > limit)) && n=$limit

    # Render entries in parallel (each runs a few git commands), then print
    # oldest-first so the newest lands next to the prompt. The subshell keeps
    # job-control noise out of interactive shells.
    local tmpdir
    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/ws.XXXXXX") || return 1
    (
        local i epoch path branch sha
        for ((i = 0; i < n; i++)); do
            IFS=$'\t' read -r epoch path branch sha <<<"${rows[$i]}"
            __ws_render_entry "$epoch" "$path" "$branch" "$sha" "$base" "$author" >"$tmpdir/$i" &
        done
        wait
    )

    ((n < total)) && echo "${__wt_dim}… $((total - n)) more (ws -a)${__wt_reset}"
    local i
    for ((i = n - 1; i >= 0; i--)); do
        cat "$tmpdir/$i"
    done
    rm -rf "$tmpdir"
}

## wd: cd into a git worktree, fuzzy-matched with fzf (wd .. → primary checkout)
# Usage: wd [query...]
# A unique fzf match jumps straight there; several matches open the fzf
# picker seeded with the query (recency-ordered, newest on top, with a
# commit-log preview); no query opens the picker over everything, with a
# ".." entry on top that pops back to the primary checkout.
function wd {
    local primary
    if [[ ${1-} == ".." ]]; then
        primary=$(__wt_primary_path) || {
            echo "wd: not in a git repository" >&2
            return 1
        }
        cd "$primary" || return 1
        local branch
        branch=$(command git branch --show-current 2>/dev/null)
        echo "${primary##*/}  [${branch:-(detached)}]"
        return
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        echo "wd: fzf not found — install it with: brew install fzf" >&2
        return 1
    fi

    local entries
    entries=$(__wt_entries) || return 1
    if [[ -z $entries ]]; then
        echo "wd: no linked worktrees" >&2
        return 1
    fi

    # Picker lines: "<name>\t<age>\t<path>\t<branch>", most recent first.
    # fzf matches on the name and shows name + age.
    local lines="" epoch path branch sha
    while IFS=$'\t' read -r epoch path branch sha; do
        lines+="${path##*/}"$'\t'"$(__wt_reltime "$epoch")"$'\t'"$path"$'\t'"$branch"$'\n'
    done <<<"$entries"

    # shellcheck disable=SC2054  # commas are literal fzf option values
    local -a fzf_ui=(
        -i --delimiter=$'\t' --nth=1 --with-nth=1,2
        --height=~50% --reverse
        --preview 'git -C {3} log --oneline -10 2>/dev/null'
        --preview-window=right,50%
    )

    local pick
    if (($#)); then
        local matches
        matches=$(printf '%s' "$lines" | fzf -i --filter="$*" --delimiter=$'\t' --nth=1)
        if [[ -z $matches ]]; then
            echo "wd: no worktree matches '$*' (try ws)" >&2
            return 1
        elif [[ $matches != *$'\n'* ]]; then
            pick=$matches
        else
            pick=$(printf '%s' "$lines" | fzf "${fzf_ui[@]}" --query="$*") || return 1
        fi
    else
        # ".." on top pops back to the primary checkout.
        if primary=$(__wt_primary_path); then
            local pbranch
            pbranch=$(command git -C "$primary" branch --show-current 2>/dev/null)
            lines=".."$'\t'"primary"$'\t'"$primary"$'\t'"${pbranch:-(detached)}"$'\n'"$lines"
        fi
        pick=$(printf '%s' "$lines" | fzf "${fzf_ui[@]}") || return 1
    fi

    IFS=$'\t' read -r _ _ path branch <<<"$pick"
    cd "$path" || return 1
    echo "${path##*/}  [$branch]"
}

## cw: Start a new Claude Code session in a fresh git worktree
# Usage: cw [name] [claude args...]
function cw {
    claude --worktree "$@"
}

function __wt_complete_wd {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local -a names=("..")
    local line first=1
    while IFS= read -r line; do
        [[ $line == worktree\ * ]] || continue
        if ((first)); then
            first=0 # skip the primary worktree
            continue
        fi
        names+=("${line##*/}")
    done < <(command git worktree list --porcelain 2>/dev/null)
    COMPREPLY=()
    while IFS= read -r line; do
        [[ -n $line ]] && COMPREPLY+=("$line")
    done < <(compgen -W "${names[*]}" -- "$cur")
}
complete -F __wt_complete_wd wd
