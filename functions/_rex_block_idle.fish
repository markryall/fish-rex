function _rex_block_idle --description 'succeeds when a rex block is back at its shell prompt: _rex_block_idle BLOCK'
    # by the path it was started as: fish 4 hardlinks fish, fish_indent and fish_key_reader
    # to one binary, so the resolved path (.name, .path) can come back as any of the three
    set -l program (rex block call -s $REX_SESSION -b $argv[1] process | jq -r '(.foreground.invoked_path // .foreground.path // "") | split("/") | last')
    contains -- $program fish zsh bash sh
end
