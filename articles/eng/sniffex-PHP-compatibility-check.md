# Checking for PHP version compatibility with PHP_CodeSniffer and PHPCompatibility

Author: [Peeter Marvet](https://github.com/petskratt)

Script that can be used to check code for compatibility with PHP version 5.6 - including easily installing
and removing dependencies in ~/bin (and our current preferences for minimal noise in reports).

## Usage

Download [`sniffex`](/scripts/generate_ssh_configs.php) script: 

```shell script
mkdir -p ~/bin && wget https://raw.githubusercontent.com/zone-eu/zone-docs/master/scripts/sniffex -O ~/bin/sniffex && chmod +x ~/bin/sniffex && sniffex init
```

```shell script
sniffex command [./path]

init      install PHP_CodeSniffer and PHPCompatibility to ~/bin
cleanup   remove installed components from ~/bin
snuff     check the provided path
```

## Ruleset

Ruleset used for checking is [`sniffex-phpcs56minimal.xml`](/scripts/sniffex-phpcs56minimal.xml).

This ruleset is made for testing large number of servers automatically, so some non-essential folders have been
excluded: logs, caches, old/new, adminer.php, some unit tests / examples and specific libraries that are most
probably unused.

If you find a single file that crashes `phpcs` then it is most probably a recursion loop in something incorrectly
detected as PHP code - for example `<?LassoScript` code or `<?php` inside `changelog.php`. Running `phpcs -v ./somepath` will list checked files and `-vv` also tokens as they are parsed.

Easiest way to exclude specific files is by adding `// phpcs:ignoreFile -- causes endless recursion in phpcs` to the beginning of file, immediately after `<?php`.