function _rex_procs_file --description 'the first of $rex_procs_files (default .dev_procs) in the current directory'
    set -l candidates .dev_procs
    set -q rex_procs_files[1]; and set candidates $rex_procs_files
    for file in $candidates
        if test -f $file
            echo $file
            return
        end
    end
    echo "no "(string join ' or ' $candidates)" here" >&2
    return 1
end
