<?php

$zoneApiKeys = [
//	'username' => 'apikeyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
];

// directories used as SSH FS mountpoints are created here
$sshFsMount = getenv( 'HOME' ) . '/sshfs';

// template for .ssh/config entries
$sshConfigTemplate = '
Host {{HOST}}
    HostName {{HOST}}
    ForwardAgent yes
    User {{USER}}
';

$sshFsAliasTemplate = '
alias mount_{{HOST}}="mkdir -p {{MOUNT}}/{{HOST}} && sshfs -o follow_symlinks -o volname={{HOST}} {{USER}}@{{HOST}}: {{MOUNT}}/{{HOST}}"
';

$sshFsFunctionTemplate = '
mount_{{HOST_SAFE}} () {
	mkdir -p {{MOUNT}}/{{HOST}}
    sshfs -o follow_symlinks {{USER}}@{{HOST}}: {{MOUNT}}/{{HOST}}
}
';

foreach ( $zoneApiKeys as $userName => $apiKey ) {

	$ch = curl_init();
	curl_setopt( $ch, CURLOPT_URL, 'https://api.zone.eu/v2/vserver' );
	curl_setopt( $ch, CURLOPT_RETURNTRANSFER, 1 );
	curl_setopt( $ch, CURLOPT_USERPWD, $userName . ":" . $apiKey );
	$headers   = [];
	$headers[] = "Content-Type: application/json";
	curl_setopt( $ch, CURLOPT_HTTPHEADER, $headers );
	$result = curl_exec( $ch );
	curl_close( $ch );

	$vservers = json_decode( $result, true );

	$sshConfig      = '';
	$sshFsFunctions = '';
	$sshFsAliases   = '';

	foreach ( $vservers as $vserver ) {
		$sshConfig      .= template_replace( $sshConfigTemplate, $vserver );
		$sshFsFunctions .= template_replace( $sshFsFunctionTemplate, $vserver );
		$sshFsAliases   .= template_replace( $sshFsAliasTemplate, $vserver );
	}

// generate ssh config - can be included into main .ssh/config:
//
	file_put_contents( getenv( 'HOME' ) . '/.ssh/' . $userName . '.config', $sshConfig );

// generate sshfs aliases - can be sourced into .bash_profile:
// for f in ~/*.alias; do source "$f"; done
// alias umount_sshfs="for f in ~/sshfs/*; do umount \"$f\"; done"
	file_put_contents( getenv( 'HOME' ) . '/' . $userName . '.alias', $sshFsAliases );

// generate sshfs mount functions (good for cron and other cases where aliases don't work)
//	$sshMountsFile = getenv( 'HOME' ) . '/' . $userName . '_mounts.sh';
//	file_put_contents( $sshMountsFile, $sshFsFunctions );
//	chmod( $sshMountsFile, 0744 );

}

echo 'All done!
Include generated configs by adding to your ~/.ssh/config:

Include *.config

To include generated aliases and allow autocomplete for ssh add to your .bash_profile:

# aliases generated from Zone API
for f in ~/*.alias; do source "$f"; done
alias umount_sshfs=\'for f in ~/sshfs/*; do umount "$f"; done\'

# *.config files generated from Zone API
complete -W "$(echo `cat ~/.ssh/config ~/.ssh/*.config | grep -E \'^Host\' | cut -d" " -f2- | tr " " "\n" | grep -v "*" | sort | uniq`;)" ssh

';



function template_replace( $template, $vserver ) {

	global $sshFsMount;

	$tags = [
		'{{HOST}}'      => $vserver['name'],
		'{{HOST_SAFE}}' => str_replace( '.', '_', $vserver['name'] ),
		'{{USER}}'      => $vserver['group'],
		'{{MOUNT}}'     => $sshFsMount,
	];

	foreach ( $tags as $tag => $value ) {
		$template = str_replace( $tag, $value, $template );
	}

	return $template;
}