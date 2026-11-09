function _rex_block_find --description 'the id of the rex block for NAME: a tab labelled NAME, or a hidden block labelled NAME'
    set -l name $argv[1]
    set -l block (rex api call -s $REX_SESSION session.view '{}' | jq -r --arg n $name '[.windows[] | select(.label == $n) | .layers[].blocks[].block_id][0] // empty')
    test -z "$block"; and set block (rex api call -s $REX_SESSION session.list_blocks '{}' | jq -r --arg n $name '[.blocks[] | select(.label == $n) | .block_id][0] // empty')
    test -n "$block"; and echo $block
end
