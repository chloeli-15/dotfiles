# dotfiles
ZSH, Tmux, Vim and ssh setup on both local/remote machines.

## Quick start on a fresh machine

```bash
git clone git@github.com:chloeli-15/dotfiles.git
cd dotfiles
./install.sh --zsh --tmux --extras   # oh-my-zsh, powerlevel10k, plugins, CLI tools
./deploy.sh --aliases=speechmatics   # wires ~/.tmux.conf and ~/.zshrc to source this repo
./claude/install.sh                  # (optional) phone push when a Claude Code session needs you
```

`install.sh` clones oh-my-zsh + the powerlevel10k theme + plugins (autosuggestions,
syntax-highlighting, completions, history-substring-search); `deploy.sh` appends
`source` lines to `~/.tmux.conf` and `~/.zshrc` so they pull config straight from this
repo (so editing files here updates your live shell). Drop `--extras` to skip the heavier
CLI tools, and adjust/omit `--aliases=...` as needed. See the detailed steps below.

> Remotes: `origin` is this fork (`chloeli-15/dotfiles`, SSH) — `git push` goes here.
> `upstream` (`jplhughes/dotfiles`) is the original; pull from it to sync.

## Installation

### Step 1
Install dependencies (e.g. oh-my-zsh and related plugins), you can specify options to install specific programs: tmux, zsh, note that your dev-vm will already have tmux and zsh installed so you don't need to provide any options in this case, but you may need to provide these if you are installing locally. 

Installation on a mac machine requires homebrew so install this [from here](https://brew.sh/) first if you haven't already.

```bash
# Install dependencies (remove tmux or zsh if you don't need to install them)
./install.sh --tmux --zsh
```

### Step 2
Deploy (e.g. source aliases for .zshrc, apply oh-my-zsh settings etc..)
```bash
# Remote linux machine
./deploy.sh  
# (optional) Deploy with extra aliases (useful for remote machines where you want specific aliases)
./deploy.sh --aliases=speechmatics
# (optional) Include simple vimrc 
./deploy.sh --vim
```

### Step 3
This set of dotfiles uses the powerlevel10k theme for zsh, this makes your terminal look better and adds lots of useful features, e.g. env indicators, git status etc...

Note that as the provided powerlevel10k config uses special icons it is *highly recommended* you install a custom font that supports these icons. A guide to do that is [here](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k). Alternatively you can set up powerlevel10k to not use these icons (but it won't look as good!)

This repo comes with a preconfigured powerlevel10k theme in [`./config/p10k.zsh`](./config/p10k.zsh) but you can reconfigure this by running `p10k configure` which will launch an interactive window. 


When you get to the last two options below
```
Powerlevel10k config file already exists.
Overwrite ~/git/dotfiles/config/p10k.zsh?
# Press y for YES

Apply changes to ~/.zshrc?
# Press n for NO 
```

## Getting to know these dotfiles

* Any software or command line tools you need, add them to the [install.sh](./install.sh) script. Try adding a new command line tool to the install script.
* Any new plugins or environment setup, add them to the [config/zshrc.sh](./config/zshrc.sh) script.
* Any aliases you need, add them to the [config/aliases.sh](./config/aliases.sh) script. Try adding your own alias to the bottom of the file. For example, try setting `cd1` to your most used git repo so you can just type `cd1` to get to it.
* Any setup you do in a new RunPod, add it to [runpod/runpod_setup.sh](./runpod/runpod_setup.sh).

## Claude Code push notifications (`claude/`)

Phone push (via [ntfy.sh](https://ntfy.sh)) when a Claude Code session needs you. See
[`claude/README.md`](./claude/README.md) for details. Setup per node:

```bash
./claude/install.sh [ntfy-topic]     # default topic: talkie-chloel-0d10764a8
```

This symlinks `~/.claude/hooks/ntfy_notify.py` → this repo and merges two hooks into
`~/.claude/settings.json` (preserving your other settings):
- **PreToolUse / AskUserQuestion** — reliable ping whenever the agent asks you a question (body =
  the question text). The dependable "needs your input" signal.
- **Notification** — permission prompts (the idle "waiting for your input" message is filtered out).

Plus an on-demand `notify` command (in `custom_bins/`, on PATH) the agent uses when it's stuck:
`notify "<message>" "<title>"`. Topic override: `CLAUDE_NTFY_TOPIC`.

Notes:
- `~/.claude` is **per-node-local**, so run `./claude/install.sh` once on each node you launch
  `claude` from, then subscribe to the topic in the ntfy phone/web app.
- After install, the **current** session needs `/hooks` (reload) or a restart to pick up the new
  hooks; new sessions get them automatically.
- Needs `python3` + outbound HTTPS to ntfy.sh. Re-running `install.sh` is safe (idempotent) and
  updates the topic.

## Making changes & pushing to master

`master` is the default branch (what a fresh machine clones), and `origin` is your fork
(`chloeli-15/dotfiles`, SSH). Most config is **live via symlinks/`source`** — editing a file here
updates your shell immediately (and the Claude hook script too), so committing is just to persist
and share across machines.

```bash
# edit files in this repo, then:
git add <files>                                  # or: git add -A
git commit -m "describe the change"
git push origin master                           # publish so other nodes can `git pull`
```

On another node, pull the latest and re-run the relevant installer if hooks/scripts changed:

```bash
git -C <dotfiles> pull origin master
./claude/install.sh                              # only if claude/ changed
```

## Docker image for runpod

To build the docker image for runpod, you can run the following command:

```bash
export DOCKER_DEFAULT_PLATFORM=linux/amd64
docker build -f runpod/johnh_dev.Dockerfile -t jplhughes1/runpod-dev .

# Build with buildx
docker buildx create --name mybuilder --use
docker buildx build --platform linux/amd64 -f runpod/johnh_dev.Dockerfile -t jplhughes1/runpod-dev . --push

```

To test it

```bash
docker run -it -v $PWD/runpod/entrypoint.sh:/dotfiles/runpod/entrypoint.sh -e USE_ZSH=true jplhughes1/runpod-dev /bin/zsh
```

To push it to docker hub

```bash
docker push jplhughes1/runpod-dev
```

