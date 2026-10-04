_pods_completions() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Basic modes and default actions
    local modes="simulate logs connect init command config recipe help"
    local default_actions="create recreate remove status update"

    # Find mode and action in the preceding words to determine context
    local mode=""
    local action=""
    
    for (( i=1; i<COMP_CWORD; i++ )); do
        local word="${COMP_WORDS[i]}"
        # Ignore flags when determining mode and action
        if [[ "$word" == -* ]]; then
            continue
        fi

        if [[ -z "$mode" ]]; then
            if [[ " $modes " =~ " $word " ]]; then
                mode="$word"
            elif [[ " $default_actions " =~ " $word " ]]; then
                mode="default"
                action="$word"
            fi
        elif [[ -z "$action" ]]; then
            # The next non-flag word after a mode is considered the action
            action="$word"
        fi
    done

    # Handle flag completions
    if [[ ${cur} == -* ]]; then
        local opts="--config --debug"
        case "$mode" in
            default|simulate)
                opts+=" --all --full"
                ;;
            logs)
                opts+=" --tail --since --until --timestamps"
                ;;
            recipe)
                opts+=" --all --orphans"
                ;;
        esac
        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
        return 0
    fi

    # If no mode has been identified yet, suggest modes and default actions
    if [[ -z "$mode" ]]; then
        COMPREPLY=( $(compgen -W "${modes} ${default_actions}" -- "${cur}") )
        return 0
    fi

    # If we have a mode but no action yet, suggest its actions
    if [[ -z "$action" ]]; then
        case "$mode" in
            simulate)
                COMPREPLY=( $(compgen -W "create recreate remove status update command logs connect" -- "${cur}") )
                ;;
            connect)
                COMPREPLY=( $(compgen -W "shell help" -- "${cur}") )
                ;;
            logs)
                COMPREPLY=( $(compgen -W "show follow" -- "${cur}") )
                ;;
            init)
                COMPREPLY=( $(compgen -W "help" -- "${cur}") )
                ;;
            command)
                COMPREPLY=( $(compgen -W "exec list help" -- "${cur}") )
                ;;
            config)
                COMPREPLY=( $(compgen -W "show edit help" -- "${cur}") )
                ;;
            recipe)
                COMPREPLY=( $(compgen -W "edit help list show" -- "${cur}") )
                ;;
            help)
                COMPREPLY=( $(compgen -W "${modes} config recipe command init logs connect" -- "${cur}") )
                ;;
        esac
    fi

    return 0
}

# Apply the completion function to the CLI commands
complete -F _pods_completions pods ./pods
