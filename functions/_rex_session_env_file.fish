function _rex_session_env_file --description 'the env file for a rex session: _rex_session_env_file [SESSION], defaults to this one'
    set -l session $REX_SESSION
    set -q argv[1]; and set session $argv[1]
    echo (_rex_session_env_dir)/(string replace session: '' -- $session).fish
end
