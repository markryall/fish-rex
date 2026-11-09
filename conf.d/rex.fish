# Env kept with rex-session-env for this rex session, so new windows and splits pick it up.
if set -q REX_SESSION
    set -l file (_rex_session_env_file)
    test -f $file; and source $file
end
