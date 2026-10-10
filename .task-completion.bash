_task_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Primary commands
    opts="verify check test build"

    # If completing the first argument (e.g., ./task <TAB>)
    if [[ ${COMP_CWORD} == 1 ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
        return 0
    fi

    # If completing the second argument after 'test' (e.g., ./task test <TAB>)
    if [[ ${COMP_CWORD} == 2 && ${prev} == "test" ]]; then
        local test_opts="dev release build"
        COMPREPLY=( $(compgen -W "${test_opts}" -- "${cur}") )
        return 0
    fi
}

# Apply the completion function to both 'task' and './task'
complete -F _task_completions ./task task
