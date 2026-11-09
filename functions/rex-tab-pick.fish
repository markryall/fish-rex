function rex-tab-pick --description 'pick any tab in any rex session with fzf and show it in the app: rex-tab-pick [QUERY]'
    set -l rows
    for session in (rex ls --json | jq -r '.sessions[].session_id')
        set -l view (rex api call -s $session session.view '{}'); or continue
        set -l slabel (printf '%s' $view | jq -r '.label')
        for window in (printf '%s' $view | jq -r '.windows[] | "\(.window_id)\t\(.label)\t\(.focused_block_id)"')
            set -l parts (string split \t $window)
            # the app's tab shows the focused pane's title; a label rex made up (Window 89abcdef) says nothing
            set -l title (rex block call -s $session -b $parts[3] title 2>/dev/null | jq -r '.title // empty')
            set -l label $parts[2]
            string match -qr '^Window [0-9a-f]{8}$' -- $label; and set label ''
            set -a rows (printf '%s\t%s\t%-16s %-28s %s' $session $parts[1] "$slabel" "$label" "$title")
        end
    end

    # rex focus moves the server's active tab without the app following, so the app is asked to show it
    set -l picked (string join \n $rows | fzf --query "$argv" --select-1 --exit-0 --delimiter \t --with-nth 3 --prompt 'tab> ' --height 40% --reverse)
    or return
    set -l ids (string split \t $picked)
    rex do session.select session_id=$ids[1] window_id=$ids[2] >/dev/null
end
