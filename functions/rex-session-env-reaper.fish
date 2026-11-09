function rex-session-env-reaper --description 'runs until the rex server goes away, dropping rex-session-env files as their sessions are destroyed: rex-session-env-reaper'
    set -l dir (_rex_session_env_dir)
    # launchd and systemd don't put rex on PATH, so fall back to the copy inside the macOS server app
    set -l rex (command -s rex)
    or set rex "$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"

    # catch sessions that ended while nothing was listening
    set -l live ("$rex" ls --json | string match -rag '"session:([^"]+)"')
    or return 1
    for file in $dir/*.fish
        contains -- (basename $file .fish) $live; or rm -f $file
    end

    "$rex" events --json | while read -l line
        set -l id (string match -rg '^\{"type":"session_destroyed","payload":\{"session_id":"session:([^"]+)"' -- $line)
        and rm -f $dir/$id.fish
    end
end
