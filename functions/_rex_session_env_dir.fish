function _rex_session_env_dir --description 'the directory holding one env file per rex session'
    set -l state ~/.local/state
    set -q XDG_STATE_HOME; and test -n "$XDG_STATE_HOME"; and set state $XDG_STATE_HOME
    echo $state/rex-session-env
end
