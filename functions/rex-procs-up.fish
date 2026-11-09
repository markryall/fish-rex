function rex-procs-up --description 'start each process in .dev_procs in a hidden rex block of this session, like tmux-up; rex-block-toggle NAME shows one: rex-procs-up'
    if not set -q REX_SESSION
        echo 'rex-procs-up: not in a rex terminal' >&2
        return 1
    end
    set -l entries (_rex_procs); or return

    for entry in $entries
        set -l item (string split -m1 \t -- $entry)[1]
        set -l command (string split -m1 \t -- $entry)[2]
        set -l block (_rex_block_find $item)
        set -l idle false
        if test -z "$block"
            # a new tab's shell may still be starting, so it counts as idle without asking
            set idle true
            set block (rex window new -s $REX_SESSION $item -c $PWD --focus=false --json | jq -r '.block_ids[0]'); or return
        end

        # a shell in the foreground means it was never started or was stopped with ctrl+c
        set -l state
        test $idle = true; or _rex_block_idle $block; and set idle true
        if test $idle = false
            set state 'already running'
        else if string match -q '*_optional*' -- $item
            # optional processes get a shell but nothing started in it
            set state 'optional, not started'
        else
            # typed into the shell rather than run as its command, so ctrl+c leaves a shell to rerun it
            rex send -s $REX_SESSION -b $block "$command"; and rex send-key -s $REX_SESSION -b $block enter
            set state started
        end

        if test "$block" != "$REX_BLOCK"
            # a hidden block has no tab, so its own label is the only name left to find it by
            rex block rename -s $REX_SESSION $block $item >/dev/null; or return
            jq -n --arg b $block '{block_id: $b}' | rex api call -s $REX_SESSION session.detach_block - >/dev/null; or return
        end
        echo "$item: $state, hidden"
    end
end
