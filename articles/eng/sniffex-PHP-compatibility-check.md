# Checking for PHP version compatibility with PHP_CodeSniffer and PHPCompatibility

Author: [Peeter Marvet](https://github.com/petskratt)

Script that can be used to check code for compatibility with PHP version 5.6 - including easily installing
and removing dependencies in ~/bin (and our current preferences for minimal noise in reports).

##Usage

```shell script
sniffex command [./path]

init      install PHP_CodeSniffer and PHPCompatibility to ~/bin
cleanup   remove installed components from ~/bin
snuff     check the provided path
```
