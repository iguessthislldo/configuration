function preexec() {
  __execution_time=$(($(date +%s%N)/1000000))
}

function precmd() {
  if [ $__execution_time ]; then
    local now=$(($(date +%s%N)/1000000))
    local elapsed=$(($now-$__execution_time))

    export RPROMPT="%F{cyan}${elapsed}ms %{$reset_color%} $RPROMT"
    unset $__execution_time
  fi
}
