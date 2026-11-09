function rex-procs-down --description 'stop each process rex-procs-up started, then close its block, hidden or not: rex-procs-down'
    if not set -q REX_SESSION
        echo 'rex-procs-down: not in a rex terminal' >&2
        return 1
    end
    set -l items (_rex_procs); or return
    set items (string split -f1 \t -- $items)

    # ctrl+c first, so servers shut down cleanly rather than being hung up on when their block closes
    rex-procs-stop; or return

    for item in $items
        set -l block (_rex_block_find $item)
        test -n "$block"; or continue
        if test "$block" = "$REX_BLOCK"
            echo "$item: not closing the pane you are typing in" >&2
            continue
        end
        rex block close -s $REX_SESSION $block >/dev/null; or return
        echo "$item: closed"
    end
end
