#!/usr/bin/env zsh

IGTD_BEGIN_SEGMENT=$'\u2591'$'\u2592'$'\u2593' # ░▒▓
IGTD_END_SEGMENT=$'\u2593'$'\u2592'$'\u2591' # ▓▒░

function segment {
    echo -n "%F{$1}"$IGTD_BEGIN_SEGMENT"%S$2%s"$IGTD_END_SEGMENT'%f '
}

# shell ======================================================================
IGTD_JOBS=$'\uf013 ' # Gear: 
IGTD_ERROR=$'\uf057 ' # circle with x: 
IGTD_RECURSIVE_SHELL=$'\u042f ' # Cryillic Capital YA: Я

# git ========================================================================
IGTD_BRANCH=$'\ue0a0' # Powerline branch symbol: 

#TODO: convert symbols below to utf8 hex like above
IGTD_CLEAN='%K{green}✔ %k'
IGTD_STAGED='%K{yellow}● %k'
IGTD_UNMERGED='%K{yellow}✖ %k' #TODO
IGTD_UNSTAGED='%K{red}✚ %k'
IGTD_UNTRACKED='%K{red}⎙ %k'
IGTD_AHEAD=$'%K{blue}\u23ed %k' # ⏭
IGTD_BEHIND=$'%K{blue}\u23ee %k' # ⏮

IGTD_CLEAN_RE="nothing to commit, working tree clean"
IGTD_STAGED_RE="Changes to be committed"
IGTD_UNSTAGED_RE="Changes not staged for commit"
IGTD_UNTRACKED_RE="Untracked files:"
IGTD_BEHIND_RE="branch is ahead"
IGTD_AHEAD_RE="branch is behind"

function igtd-git-prompt-check {
    if echo $1 | grep $2 &> /dev/null
    then
        echo -n $3
    fi
}

function igtd-git-prompt {
    if git_status="$(git status 2>/dev/null)"
    then
        printf ' %s %s (%s) '\
               "$IGTD_BRANCH"\
               "$(echo $git_status | sed -n 's/On branch \(.*\)/\1/p')"\
               "$(git rev-parse --short HEAD 2>/dev/null)"
        igtd-git-prompt-check "$git_status" "$IGTD_CLEAN_RE" "$IGTD_CLEAN"
        igtd-git-prompt-check "$git_status" "$IGTD_STAGED_RE" "$IGTD_STAGED"
        igtd-git-prompt-check "$git_status" "$IGTD_UNSTAGED_RE" "$IGTD_UNSTAGED"
        igtd-git-prompt-check "$git_status" "$IGTD_UNTRACKED_RE" "$IGTD_UNTRACKED"
        igtd-git-prompt-check "$git_status" "$IGTD_AHEAD_RE" "$IGTD_AHEAD"
        igtd-git-prompt-check "$git_status" "$IGTD_BEHIND_RE" "$IGTD_BEHIND"
        return 0
    fi
    return 1
}

function prompt_git {
    local result
    if result=$(igtd-git-prompt)
    then
        segment white $result
    fi
}

# Notify If These Variables Are Exported =====================================
function igtd-var-notify {
    local result
    result=""
    typeset -A var_notify
    var_notify[DDS_ROOT]=D
    var_notify[ACE_ROOT]=A
    var_notify[TAO_ROOT]=T

    local var
    for var in $(env | cut -d '=' -f 1)
    do
        if [ -n ${var_notify[$var]+x} ]
        then
            result="$result${var_notify[$var]}"
        fi
    done

    if [ -n "$result" ]
    then
        segment magenta $result
    fi
}

# Tie it all together ========================================================
function prompt_top {
    segment blue '%n @ %M'

    segment yellow "$(date +%T)"

    # Show Job Count if > 1
    echo -n "%(1j.$(segment cyan "$IGTD_JOBS %j").)"

    # Show Shell Level if > 2
    echo -n "%(2L.$(segment cyan "$IGTD_RECURSIVE_SHELL %L").)"

    igtd-var-notify

    prompt_git
}

PROMPT='%(?..$(segment red "$IGTD_ERROR %?"))$(prompt_top)
$IGTD_BEGIN_SEGMENT%S%1(CC%~C)%#%s'
#RPROMPT='%(?..$(segment red "$IGTD_ERROR %?"))'
