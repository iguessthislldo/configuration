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
IGTD_GIT=$'\ue702' # 
IGTD_BRANCH=$'\ue0a0' # Powerline branch symbol: 
IGTD_COMMIT=$'\ue729' # 
IGTD_TAG=$'\uf02b' # 

#TODO: convert symbols below to utf8 hex like above
IGTD_CLEAN='%K{green}✔ %k'
IGTD_STAGED='%K{yellow}󰋗 %k'
IGTD_UNMERGED='%K{yellow}✖ %k' #TODO
IGTD_UNSTAGED='%K{red}✚ %k'
IGTD_UNTRACKED='%K{red}⎙ %k'
IGTD_AHEAD='%K{blue}  %k'
IGTD_BEHIND='%K{blue}  %k'

IGTD_CLEAN_RE="nothing to commit, working tree clean"
IGTD_STAGED_RE="Changes to be committed"
IGTD_UNSTAGED_RE="Changes not staged for commit"
IGTD_UNTRACKED_RE="Untracked files:"
IGTD_BEHIND_RE="branch is ahead"
IGTD_AHEAD_RE="branch is behind"

function igtd-git-prompt-check {
    if [[ "$1" =~ "$2" ]]
    then
        echo -n $3
    fi
}

function igtd-git-prompt {
    if git_status="$(git status 2>/dev/null)"
    then
        echo -n " $IGTD_GIT "
        if [[ "$git_status" =~ 'On branch ([[:graph:]]+)' ]]
        then
            echo -n "$IGTD_BRANCH${match[1]}"
        fi
        if [[ "$git_status" =~ 'HEAD detached at ([[:graph:]]+)' ]]
        then
            echo -n "$IGTD_TAG ${match[1]}"
        fi
        printf " $IGTD_COMMIT %s " \
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
    local count
    count=${#IGTD_VAR_NOTIFY[@]}
    local i
    for ((i = 0; i < count; ++i))
    do
        local name_value="${IGTD_VAR_NOTIFY[@]:$i:1}"
        i=$((i+1))
        local symbol="${IGTD_VAR_NOTIFY[@]:$i:1}"
        if [[ $name_value =~ ^([^=]+)=(.*) ]]
        then
            if [[ "$(print -rl -- ${(P)match[1]})" == "${match[2]}" ]]
            then
                result="$result$symbol"
            fi
        else
            if [[ -v $name_value ]]
            then
                result="$result$symbol"
            fi
        fi
    done

    if [ -n "$result" ]
    then
        segment magenta $result
    fi
}

# Tie it all together ========================================================
function igtd-cmd-status {
    local str
    if [ -n "${IGTD_CMD_EXIT_STATUS}" ]
    then
        str="$(segment red "$IGTD_ERROR ${IGTD_CMD_EXIT_STATUS}")"
    fi
    if [ -n "$IGTD_CMD_TIME" ]
    then
        str="$str$(segment green "${IGTD_CMD_TIME}" )"
    fi
    if [ -n "$str" ]
    then
        echo -n "$str"
    fi
}

function prompt_top {
    if [ ! -z ${SSH_CLIENT+x} ]
    then
        segment blue '%n @ %M'
    fi

    if [ ! -z ${IGTD_ENV_NAME+x} ]
    then
        segment magenta "${IGTD_ENV_NAME}"
    fi

    segment yellow "$(date +%T)"

    # Show Job Count if > 1
    echo -n "%(1j.$(segment cyan "$IGTD_JOBS %j").)"

    # Show Shell Level if > 2
    echo -n "%(2L.$(segment cyan "$IGTD_RECURSIVE_SHELL %L").)"

    igtd-var-notify

    prompt_git
}

PROMPT='$(igtd-cmd-status)
$(prompt_top)
$IGTD_BEGIN_SEGMENT%S%1(CC%~C)%#%s'
