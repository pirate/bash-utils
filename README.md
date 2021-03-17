# bash-utils
A collection of hand-crafted bash scripts for various common tasks.

## Reading List

 - ShellCheck: life-changing BASH linter and testing toolkit              https://github.com/koalaman/shellcheck
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
 - Useful BASH and UNIX commands                                          https://cb.vu/unixtoolbox.xhtml
 - When Bash Scripts Bite :: Jane Street Tech Blogs                       https://blogs.janestreet.com/when-bash-scripts-bite/
 - Bashible: Ansible-like framework for bash-based devops                 https://github.com/mig1984/bashible
 - Auto-parse help text from comment at the top of script                 https://samizdat.dev/help-message-for-shell-scripts/
 - Make bash scripts safer by writing them in Rust                        https://github.com/rust-shell-script/rust_cmd_lib
 - Additional shell options for non-trivial bash scripts                  https://saveriomiroddi.github.io/Additional-shell-options-for-non-trivial-bash-shell-scripts/
 - Bash unit testing framework                                            https://github.com/pgrange/bash_unit

For my Fish shell functions, snippets, and reading list see here:  
https://github.com/pirate/fish-functions

## Code Layout

- `bin/` is a collection of finished scripts, for doing everything you need to do related to a specific task (e.g. `dns` can both set and fetch DNS values from a variety of providers)
- `lib/` is a collection of adapters to interact with 3rd party tools or scripts, e.g. cloudflare/letsencrypt/etc
- `util/` is a collection of pure bash functions to make development in bash easier e.g. logging/configuration/error handling/etc.
