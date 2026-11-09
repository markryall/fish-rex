complete -c rex-block-toggle -f -a '(rex-block-toggle 2>/dev/null | string replace -r "^(\S+)\s+(.*)\$" "\$2\t\$1")'
