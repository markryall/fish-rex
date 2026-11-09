# fish-rex

Fish functions for working in Rex the way people
used to work in tmux: one session per project, environment that every pane in the
session shares, and the project's servers running in background blocks you can pop
up when you need them.

```fish
fisher install markryall/fish-rex
```

Needs `rex` and `jq`; `rex-tab-pick` also needs `fzf`.

## The workflow

A session per project. Open a Rex session for the project and name it:

```fish
cd ~/code/my-app
rex-session-rename            # labels the session my-app; or rex-session-rename "my app"
```

Load the project's environment once, for the whole session. Rex has no
`tmux set-environment`, so `rex-session-env` keeps a per-session file that
`conf.d/rex.fish` sources in every new shell of that session. New tabs and splits
start with the same env, and other sessions don't see it:

```fish
rex-session-env AWS_PROFILE=staging   # set and keep
rex-session-env DATABASE_URL          # keep the value it already has here
rex-session-env -e AWS_PROFILE        # drop it, here and for new shells
rex-session-env                       # list what's kept
```

Most project env comes from a script, not by hand. `rex-session-env-run` runs a
command in this shell and keeps every exported var it set, changed or removed:

```fish
rex-session-env-run source .env.fish
rex-session-env-run load-my-project-env staging
```

Start the project's processes. List them in `.dev_procs`, one per line, like a
Procfile. A line can be `name: command`. A bare name runs
`$rex_procs_command` with `{}` replaced by the name, which is `mise run {}` unless
you set it, so a project that already has a task per process only needs to list
the names:

```
# .dev_procs
web: bin/rails server -p 3000
worker: bundle exec sidekiq
webpack
storybook_optional
```

Here `webpack` runs `mise run webpack`. Comments go on their own line.

```fish
rex-procs-up
```

Each process gets its own block in this session, and then the block is hidden. It
keeps running but takes up no tab. A name containing
`_optional` gets a shell but nothing is started in it. The command is typed into
the block's shell rather than being its command, so ctrl+c leaves a shell to run it
again from. Running `rex-procs-up` again only starts what isn't already running.

Look at one when you need it:

```fish
rex-block-toggle                 # list the blocks that can be shown or hidden
rex-block-toggle web             # shows it as a popup over this tab
rex-block-toggle web             # hides it again, still running
```

Stop them all with ctrl+c and wait for each one to get back to its prompt, for
example to pull and migrate before starting them again:

```fish
rex-procs-stop
git pull; and bin/setup
rex-procs-up
```

Or stop them and close their blocks:

```fish
rex-procs-down
```

Jump to any tab in any session:

```fish
rex-tab-pick           # fzf over every tab, showing session, tab label and title
rex-tab-pick api       # starts the search at "api", and goes straight there if only one tab matches
```

## Functions

| Function | What it does |
| --- | --- |
| `rex-session-rename [LABEL]` | Renames this session (defaults to the directory name) |
| `rex-session-env [NAME[=VALUE]]..` | Keeps vars for every new shell in this session; `-e NAME` drops them; no args lists them |
| `rex-session-env-run CMD..` | Runs a command and keeps every exported var it changes |
| `rex-session-env-reaper` | Long-running: deletes a session's env file when the session is destroyed |
| `rex-procs-up` | Starts each process in `.dev_procs` in a hidden block |
| `rex-procs-stop` | Sends ctrl+c to each one and waits for its shell |
| `rex-procs-down` | Stops them, then closes their blocks |
| `rex-block-toggle [NAME]` | Hides a block, or shows a hidden one as a popup; no NAME lists them |
| `rex-tab-pick [QUERY]` | Picks a tab in any session with fzf and shows it |

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `rex_procs_files` | `.dev_procs` | Process files to look for, in order; the first one found wins |
| `rex_procs_command` | `mise run {}` | Command for each bare name in the procs file, with `{}` replaced by the name |
| `rex_session_env_skip` | | Extra vars `rex-session-env-run` never keeps |

```fish
set -g rex_procs_files .dev_procs .tmux_windows   # while some repos still use the old name
set -g rex_procs_command 'just {}'
```

`rex-session-env-run` never keeps vars that only make sense in the shell that set
them: `PWD`, `OLDPWD`, `SHLVL`, `PATH`, the `REX_*` ids, `__MISE_*` and `DYLD_*`.

Session env files are kept in `$XDG_STATE_HOME/rex-session-env` (default
`~/.local/state/rex-session-env`), readable only by you, because they often hold
tokens.

## Short names

The functions have long names so they won't clash with anything else you have,
and so they group together when you tab-complete `rex-`. Give the ones you use
most a short name. Abbreviations work well, because your history records the full
command. For example:

```fish
abbr --add rn rex-session-rename
abbr --add senv rex-session-env
abbr --add senv-run rex-session-env-run
abbr --add rt rex-block-toggle
abbr --add rex-tab rex-tab-pick
abbr --add rex-stop rex-procs-stop
abbr --add rex-down rex-procs-down
```

An abbreviation only expands when you type it at the prompt. If another function
calls one of these, it has to use the full name. When you need to add your own
behaviour, write a wrapper function instead. For example, this skips the processes
when docker runs them:

```fish
function rex-up
    if set -q MY_DOCKER_DEV
        echo 'rex-up: skipping, docker runs these' >&2
        return
    end
    rex-procs-up
end
```

## Cleaning up session env

`rex-session-env` deletes the files of ended sessions whenever it writes. To
delete them as soon as a session is destroyed, keep `rex-session-env-reaper`
running. On macOS, use a launchd agent:

```xml
<!-- ~/Library/LaunchAgents/rex-session-env-reaper.plist -->
<plist version="1.0">
<dict>
  <key>Label</key><string>rex-session-env-reaper</string>
  <key>ProgramArguments</key>
  <array>
    <string>/opt/homebrew/bin/fish</string>
    <string>-c</string>
    <string>rex-session-env-reaper</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>30</integer>
</dict>
</plist>
```

```sh
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/rex-session-env-reaper.plist
```

`KeepAlive` restarts it when the Rex server goes away and comes back.

## A key to hide popups

`rex-block-toggle NAME` hides a popup again, but a key is quicker. Put this in
`~/.config/rex/init.lua` to hide a floating pane with shift+cmd+h. A tiled pane is
left alone:

```lua
local function layer_of(view, block_id)
  for _, window in ipairs(view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        if block.block_id == block_id then return layer end
      end
    end
  end
end

rex.action{
  name = "hide_popup",
  title = "Hide Popup",
  description = "Hide the focused pane if it's floating. It keeps running, and rex-block-toggle NAME shows it again.",
  args = { block_id = "string?" },
  run = function(ctx, args)
    local block_id = (args and args.block_id) or ctx.block_id
    local view, err = rex.session.view{}
    if not view then error(err) end
    local layer = layer_of(view, block_id)
    if not layer or layer.kind == "tiled" then return false end
    local _, derr = rex.session.detach_block{ block_id = block_id }
    if derr then error(derr) end
    return true
  end,
}

rex.bind("shift+cmd+h", "hide_popup")
```

## License

MIT
