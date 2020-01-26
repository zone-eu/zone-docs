# Generating SSH config and SSHFS mount aliases using Zone API

Author: [Peeter Marvet](https://github.com/petskratt), original idea / script from [Ingmar Aasoja](https://github.com/ybr-nx)

Managing SSH accounts on multiple servers is made easier with `~/.ssh/config`, where 
you can specify username and other options for each hostname:

```sshconfig
Host example.com
    HostName example.com
    ForwardAgent yes
    User virt11111
```

... so instead of `ssh virt11111@example.com` you can do just `ssh example.com`.

Connecting to these accounts using SSHFS can be made easier using alias:

```shell
alias mount_example.com="mkdir -p ~/sshfs/example.com && sshfs -o follow_symlinks -o volname=example.com virt11111@example.com: ~/sshfs/example.com"
```

But when you have A LOT of servers even managing and updating these config entries and aliases becomes a burden.

### Generating config files and aliases

With Zone API you can generate config entries for all servers you have access to,
e.g these are on your account or delegated to you (with full rights).

Download [generate_ssh_configs.php](/scripts/generate_ssh_configs.php) and add your 
API credentials to array:

```php
$zoneApiKeys = [
	'zoneidusername' => 'apikeyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
];
```

And run it:

````shell script
php generate_ssh_configs.php
````

Script will generate config files `~/.ssh/[zoneidusername].config` and as an additional
feature also aliases for mounting these accounts using SSHFS in `~/[zoneidusername].alias`.

### Including in main config

To use these add to your `~/.ssh/config`:

```sshconfig
Include *.config
```

As `ssh` uses first match from `~/.ssh/config` you can override generated host entries by placing 
an entry before the `Include`.

### Creating aliases

Add to your `~/.bash_profile` if you'd like to use SSHFS:

```shell
# aliases generated from Zone API
for f in ~/*.alias; do source "$f"; done
alias umount_sshfs='for f in ~/sshfs/*; do umount "$f"; done'

# *.config files generated from Zone API
complete -W "$(echo `cat ~/.ssh/config ~/.ssh/*.config | grep -E '^Host' | cut -d" " -f2- | tr " " "\n" | grep -v "*" | sort | uniq`;)" ssh
```

Undocumented features:
* you can unmount all SSHFS shares with `umount_sshfs`
* all hosts in config will appear as `ssh` autocomplete suggestions

### ToDo

* we need physical server hostname or IP in API so configs can work also when actual hostname directs elsewhere (or uses dedicated IP)
* add support for command-line arguments (what to create? for which ZoneID?)
* add support for checking / adding SSH keys and whitelisted IPs to accounts
