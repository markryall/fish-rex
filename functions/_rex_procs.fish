function _rex_procs --description 'NAME<tab>COMMAND for each process in the procs file: a bare NAME runs $rex_procs_command, NAME: COMMAND runs COMMAND'
    set -l file (_rex_procs_file); or return
    # each bare NAME is run as this command, {} standing for the name
    set -l template 'mise run {}'
    set -q rex_procs_command; and set template $rex_procs_command
    for line in (string trim <$file)
        test -n "$line"; or continue
        string match -q '#*' -- $line; and continue
        set -l parts (string match -rg '^([^:\s]+)\s*:\s*(.+)$' -- $line)
        if set -q parts[2]
            printf '%s\t%s\n' $parts[1] $parts[2]
        else
            printf '%s\t%s\n' $line (string replace -a '{}' $line -- $template)
        end
    end
end
