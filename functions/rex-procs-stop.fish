function rex-procs-stop --description 'ctrl+c each process rex-procs-up started, hidden or not, and wait for its shell: rex-procs-stop'
    if not set -q REX_SESSION
        echo 'rex-procs-stop: not in a rex terminal' >&2
        return 1
    end
    set -l items (_rex_procs); or return
    set items (string split -f1 \t -- $items)

    set -l stopping
    for item in $items
        set -l block (_rex_block_find $item)
        if test -z "$block"
            echo "$item: not open"
            continue
        end
        if _rex_block_idle $block
            echo "$item: not running"
            continue
        end
        rex send-key -s $REX_SESSION -b $block ctrl+c
        set -a stopping "$item $block"
    end

    # rex-procs-up types into the shell, so it has to be back at its prompt first or the command goes to the dying process
    for entry in $stopping
        set -l parts (string split ' ' $entry)
        set -l stopped
        for i in (seq 60)
            if _rex_block_idle $parts[2]
                set stopped yes
                break
            end
            sleep 0.5
        end
        if set -q stopped[1]
            echo "$parts[1]: stopped"
        else
            echo "$parts[1]: still running after 30s" >&2
        end
    end
end
