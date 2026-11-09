function rex-block-toggle --description 'hide a rex block (it keeps running, out of every tab) or show it again as a popup over this tab: rex-block-toggle NAME'
    if not set -q REX_SESSION; or not set -q REX_BLOCK
        echo 'rex-block-toggle: not in a rex terminal' >&2
        return 1
    end
    if test (count $argv) -eq 0
        # hidden blocks by their own label, shown ones by the label of the tab they're alone in
        rex api call -s $REX_SESSION session.list_blocks '{}' | jq -r '.blocks[] | select(.placement == "detached") | "hidden  \(.label)"'
        rex api call -s $REX_SESSION session.view '{}' | jq -r --arg me $REX_BLOCK '.windows[] | select([.layers[].blocks[]] | length == 1) | select(.layers[0].blocks[0].block_id != $me) | "shown   \(.label)"'
        return
    end
    if test (count $argv) -ne 1
        echo 'usage: rex-block-toggle [NAME]   (a tab label, block label or block id; no NAME lists what can be toggled)' >&2
        return 1
    end
    set -l name $argv[1]

    set -l blocks (rex api call -s $REX_SESSION session.list_blocks '{}'); or return
    set -l found (printf '%s' $blocks | jq -r --arg n $name '[.blocks[] | select(.block_id == $n or .label == $n)][0] // empty | "\(.block_id) \(.placement)"')

    # rex-procs-up labels the tab, not the block, so a placed block is also found by its tab's label
    if test -z "$found"
        set -l view (rex api call -s $REX_SESSION session.view '{}'); or return
        set -l ids (printf '%s' $view | jq -r --arg n $name '.windows[] | select(.label == $n) | .layers[].blocks[].block_id')
        if test (count $ids) -gt 1
            echo "rex-block-toggle: tab $name has more than one pane; name the block instead" >&2
            return 1
        end
        test (count $ids) -eq 1; and set found "$ids[1] placed"
    end
    if test -z "$found"
        echo "rex-block-toggle: no tab or block called $name" >&2
        return 1
    end

    set -l block (string split ' ' $found)[1]
    set -l placement (string split ' ' $found)[2]

    if test $placement = detached
        # a detached block can't float straight away, so it's placed beside this pane first, floated, then focused
        set -l args (jq -nc --arg b $block --arg a $REX_BLOCK '{block_id: $b, anchor_block_id: $a}')
        rex api call -s $REX_SESSION session.move_block $args >/dev/null; or return
        set args (jq -nc --arg b $block '{block_id: $b, bounds: [0.05, 0.05, 0.9, 0.9]}')
        rex api call -s $REX_SESSION session.float_block $args >/dev/null; or return
        set args (jq -nc --arg b $block '{block_id: $b}')
        rex api call -s $REX_SESSION session.focus_block $args >/dev/null; or return
        echo "$name: shown, rex-block-toggle $name hides it again"
    else
        if test $block = $REX_BLOCK
            echo 'rex-block-toggle: not hiding the pane you are typing in' >&2
            return 1
        end
        # a detached block has no tab, so its own label is the only name left to find it by
        rex block rename -s $REX_SESSION $block $name >/dev/null; or return
        jq -n --arg b $block '{block_id: $b}' |
            rex api call -s $REX_SESSION session.detach_block - >/dev/null; or return
        echo "$name: hidden"
    end
end
