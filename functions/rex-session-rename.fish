function rex-session-rename --description 'rename this rex session: rex-session-rename [LABEL], defaults to the current directory name'
    if not set -q REX_SESSION
        echo 'rex-session-rename: not in a rex session' >&2
        return 1
    end
    set -l label (string join ' ' $argv)
    test -n "$label"; or set label (basename $PWD)
    rex session rename $REX_SESSION $label
end
