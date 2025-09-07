# bash-utils

A collection of my hand-crafted bash scripts and helper functions for various common tasks.

## Code Layout

- `bin/` is a collection of finished scripts, for doing everything you need to do related to a specific task (e.g. `dns` can both set and fetch DNS values from a variety of providers)
- `lib/` is a collection of adapters to interact with 3rd party tools or scripts, e.g. cloudflare/letsencrypt/etc
- `util/` is a collection of pure bash functions to make development in bash easier e.g. logging/configuration/error handling/etc.


## Reading List

For a list of my favorite CLI utilities for Linux/macOS, and much more, see here: 

https://docs.sweeting.me/s/system-monitoring-tools ⭐️

For my **Fish shell** functions, snippets, and reading list see here:  

https://github.com/pirate/fish-functions

### Manpages and CLI Explainer Tools

- https://linux.die.net/man/
- https://wiki.tilde.fun/admin/linux/cli/start
- https://explainshell.com/ ([Github](https://github.com/idank/explainshell))
- https://tldr.sh/
- http://bropages.org/
- https://regex101.com/

### Articles, Tools, and More

 - ShellCheck: life-changing BASH linter and testing toolkit              https://github.com/koalaman/shellcheck
 - How to do things safely in bash                                        https://github.com/anordal/shellharden/blob/master/how_to_do_things_safely_in_bash.md
 - 30 interesting commands for the Linux shell – Víctor López Ferrando    https://www.lopezferrando.com/30-interesting-shell-commands/
 - 7 Surprising Bash Variables                                            https://zwischenzugs.com/2019/05/11/seven-surprising-bash-variables/
 - anordal/shellharden                                                    https://github.com/anordal/shellharden/blob/master/how_to_do_things_safely_in_bash.md
 - barryclark/bashstrap                                                   https://github.com/barryclark/bashstrap
 - BashPitfalls : Greg's Wiki                                             http://mywiki.wooledge.org/BashPitfalls
 - Common shell script mistakes                                           http://www.pixelbeat.org/programming/shell_script_mistakes.html
 - Comparison of all the UNIX shells                                      http://hyperpolyglot.org/unix-shells
 - Defensive Bash Programming                                             https://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/index.html or https://jonlabelle.com/snippets/view/markdown/defensive-bash-programming
 - Bash FAQ and Cookbook                                                  https://mywiki.wooledge.org/BashFAQ
 - Detecting the use of "curl | bash" server side                         https://idontplaydarts.com/2016/04/detecting-curl-pipe-bash-server-side
 - Gensokyo Blog - Use Bash Builtins shell,fish,bash                      https://blog.gensokyo.io/a/fafbe742.html
 - Rich’s sh (POSIX shell) tricks                                         http://www.etalabs.net/sh_tricks.html
 - Shell Scripts Matter                                                   https://dev.to/thiht/shell-scripts-matter
 - Shell Style Guide                                                      https://google.github.io/styleguide/shell.xml
 - Shellcode Injection - Dhaval Kapil                                     https://dhavalkapil.com/blogs/Shellcode-Injection/
 - Something you didn't know about functions in bash                      http://catonmat.net/blog/bash-functions
 - Ten More Things I Wish I’d Known About bash                            https://zwischenzugs.com/2018/01/21/ten-more-things-i-wish-id-known-about-bash
 - Ten Things I Wish I’d Known About bash                                 https://zwischenzugs.com/2018/01/06/ten-things-i-wish-id-known-about-bash
 - Testing Bash scripts with BATS                                         https://opensource.com/article/19/2/testing-bash-bats
 - Testing Bash scripts with Critic.sh                                    https://github.com/Checksum/critic.sh
 - Useful BASH and UNIX commands                                          [https://cb.vu/unixtoolbox.xhtml](https://web.archive.org/web/20210916210855/http://cb.vu/unixtoolbox.xhtml)
 - When Bash Scripts Bite :: Jane Street Tech Blogs                       https://blogs.janestreet.com/when-bash-scripts-bite/
 - Bashible: Ansible-like framework for bash-based devops                 https://github.com/mig1984/bashible
 - Auto-parse help text from comment at the top of script                 https://samizdat.dev/help-message-for-shell-scripts/
 - Make bash scripts safer by writing them in Rust                        https://github.com/rust-shell-script/rust_cmd_lib
 - Additional shell options for non-trivial bash scripts                  https://saveriomiroddi.github.io/Additional-shell-options-for-non-trivial-bash-shell-scripts/
 - Bash unit testing framework                                            https://github.com/pgrange/bash_unit
 - What exactly was the point of `[ “x$var” = “xval” ]`?                  https://www.vidarholen.net/contents/blog/?p=1035
 - How to Write Indempotent Bash Scripts                                  https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/
 - Better Bash Scripting in 15 Minutes                                    http://robertmuth.blogspot.com/2012/08/better-bash-scripting-in-15-minutes.html
 - Argbash: Argument parsing toolkit                                      https://github.com/matejak/argbash
 - Bash Exit Traps: Towards Safer Bash Scripts                            http://redsymbol.net/articles/bash-exit-traps/
 - Advanced Bash Scripting Guide by Mendel Cooper                         https://hangar118.sdf.org/p/bash-scripting-guide/
 - Bash Debugging Zine by Julia Evans                                     https://wizardzines.com/comics/bash-debugging/
 - Bash Process Backgrounding and Daemon Management                       https://mywiki.wooledge.org/ProcessManagement
 - The Art of Command Line                                                https://github.com/jlevy/the-art-of-command-line
 - Basn $Namerefs                                                         https://rednafi.com/misc/bash_namerefs/
 - Bash Here Strings `<<<`                                                https://www.gnu.org/software/bash/manual/bash.html#Here-Strings

If any of these links are down, see https://archive.sweeting.me or https://archive.org for mirrors.

---

## Useful Helper Commands

#### Unofficial Bash Strict Mode

```bash
#!/usr/bin/env bash

### Bash Environment Setup
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# set -o xtrace
# set -x
# shopt -s nullglob
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
IFS=$'\n'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
```

#### `timeout`

timeout executes the ssh command (with args) and sends a SIGTERM if ssh doesn't return after 5 second. for more details about timeout, read this document： http://man7.org/linux/man-pages/man1/timeout.1.html

```bash
timeout 5 some-slow-command

# or on mac:
brew install coreutils
gtimeout 5 some-slow-command
```

https://news.ycombinator.com/item?id=44096395 more lore around `timeout`

#### `until`

```bash
until curl --silent --fail-with-body 10.0.0.1:8080/health; do
	sleep 1
done
```

https://heitorpb.github.io/bla/timeout/

#### `nohup`

#### `expect`

#### `trap`

#### `getopts` / `argbash`

```bash
# parse and handle passed CLI arguments sanely
while getopts ":mnopq:rs" Option
do
  case $Option in
    m     ) echo "Scenario #1: option -m-   [OPTIND=${OPTIND}]";;
    n | o ) echo "Scenario #2: option -$Option-   [OPTIND=${OPTIND}]";;
    p     ) echo "Scenario #3: option -p-   [OPTIND=${OPTIND}]";;
    q     ) echo "Scenario #4: option -q-\
                  with argument \"$OPTARG\"   [OPTIND=${OPTIND}]";;
    #  Note that option 'q' must have an associated argument,
    #+ otherwise it falls through to the default.
    r | s ) echo "Scenario #5: option -$Option-";;
    *     ) echo "Unimplemented option chosen.";;   # Default.
  esac
done
```

#### `trap`

```bash
#!/bin/bash
scratch=$(mktemp -d -t tmp.XXXXXXXXXX)
function finish {
  rm -rf "$scratch"
}
trap finish EXIT
```

#### `pkill`

```bash
# kill any processes matching given regex
pkill nginx
```

#### `eval`

```bash
a='$b'
b='$c'
c=d

echo $a             # $b
                    # First level.
eval echo $a        # $c
                    # Second level.
eval eval echo $a   # d
                    # Third level.
```

#### `exec`

```bash
# This shell builtin replaces the current process with a specified command
# useful for when the last command in a script is a long running process you want to kick off, and you dont want it to be a child of bash

exec some-daemon-that-runs-forever
```

#### `dpkg -s <pkgname>` / `dpkg --compare-versions "20.04.2" "ge" "18.04.12"`

check pkg info of any installed package, and compare semver/date/incremental versions easily

#### `pipeexec`

Have total control over piping between processes, including doing crazy things like piping a processes own stdout into its stdin, launching complex directed graphs of pipes as a single process, etc.

https://github.com/flonatel/pipexec


### `perl -pE`: Best simple find-and-replace regex

```bash
echo '0.0.0.0:443->443/tcp' | perl -pE 's/0.0.0.0:(\d+)->.*/$1/gm'    # 443
```

#### `sed`: Truncate strings with `...` ellipsis

```bash
# Example: Truncate if longer than 15 characters
echo "short string"     | sed 's/\(.\{15\}\).*/\1.../'       # short string
echo "some long string" | sed 's/\(.\{15\}\).*/\1.../'       # some long st...

# Bonus: get terminal width in columns
TERMINAL_WIDTH=$(tput cols)
```

#### Use strace to catch syscall failures

```bash
strace -e trace=clone -e fault=clone:error=EAGAIN
```
https://medium.com/@manav503/using-strace-to-perform-fault-injection-in-system-calls-fcb859940895


