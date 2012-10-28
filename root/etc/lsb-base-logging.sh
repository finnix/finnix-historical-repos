. /lib/finnix/finnix-colors.sh

log_success_msg () {
    echo "${WHITE}[${BLUE}*${WHITE}]${NORMAL} $@"
}

log_failure_msg () {
    echo "${WHITE}[${RED}*${WHITE}]${NORMAL} $@"
}

log_warning_msg () {
    echo "${WHITE}[${YELLOW}*${WHITE}]${NORMAL} $@"
}

log_begin_msg () {
    if [ -z "${1:-}" ]; then
        return 1
    fi
    echo -n "${WHITE}[${BLUE}*${WHITE}]${NORMAL} $@..."
}

log_daemon_msg () {
    if [ -z "${1:-}" ]; then
        return 1
    fi

    if [ -z "${2:-}" ]; then
        echo -n "${WHITE}[${BLUE}*${WHITE}]${NORMAL} $1..."
        return
    fi

    echo -n "${WHITE}[${BLUE}*${WHITE}]${NORMAL} $1... $2"
}

log_progress_msg () {
    if [ -z "${1:-}" ]; then
        return 1
    fi
    echo -n " $@"
}


log_end_msg () {
    [ -z "${1:-}" ] && return 1

    if [ $1 -eq 0 ]; then
        echo " done"
    else
        echo " ${RED}failed!${NORMAL}"
    fi
    return $1
}


log_action_msg () {
    [ "$@" = "Using makefile-style concurrent boot in runlevel 0" ] && return 0
    [ "$@" = "Using makefile-style concurrent boot in runlevel 2" ] && return 0
    [ "$@" = "Using makefile-style concurrent boot in runlevel 6" ] && return 0
    echo "${WHITE}[${BLUE}*${WHITE}]${NORMAL} $@"
}

log_action_begin_msg () {
    echo -n "${WHITE}[${BLUE}*${WHITE}]${NORMAL} $@..."
}

log_action_cont_msg () {
    echo -n "$@..."
}

log_action_end_msg () {
    if [ -z "${2:-}" ]; then
        end=""
    else
        end=" ($2)"
    fi

    if [ $1 -eq 0 ]; then
        echo " done${end}"
    else
        echo " ${RED}failed${end}${NORMAL}"
    fi
}
