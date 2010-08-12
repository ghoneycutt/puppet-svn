# Class: svn
#
# This module manages svn
#
class svn {

    package { "subversion": }

    # Definition: svn::checkout
    #
    # checkout/switch an svn repository
    # Note that the owner/group case statements are a hack and need to be refactored
    #
    # Parameters:   
    #   $reposerver - server name of svn repo
    #   $method     - protocol for which you are connecting
    #   $repopath   - path to repository on remote server
    #   $branch     - which branch under $repopath
    #   $workingdir - local directory
    #   $remoteuser - optional remote user, defaults to not being 
    #   $localuser  - user on local system that initiates the svn connection
    #
    # Actions:
    #   checkout/switch an svn repository
    #
    # Requires:
    #   $reposerver
    #   $method
    #   $repopath
    #   $brnach
    #   $workingdir
    #   $localuser
    #
    # Sample Usage:
    #    svn::checkout { "dns $dns_branch":
    #        reposerver => "bindRepoServer",
    #        method     => "http",
    #        repopath   => "dns",
    #        workingdir => "/var/named/chroot/var/named/zones",
    #        branch     => "$dns_branch",
    #        localuser  => "dnsreposvn",
    #        require    => Package["bind-chroot"],
    #        notify     => Service["named"],
    #    } # svn::checkout
    #
    define checkout($reposerver, $method, $repopath, $branch, $workingdir, $remoteuser = false, $localuser) {

        Exec {
            path => "/bin:/usr/bin:/usr/local/bin",
            user        => $localuser,
            environment => $localuser ? {
                puppet      => "HOME=/var/lib/puppet",
                dnsreposvn  => "HOME=/home/dnsreposvn",
                },
        } # Exec

        $svn_command_checkout = $remoteuser ? {
            false   => "svn checkout --non-interactive $method://$reposerver/$repopath/$branch $workingdir",
            default => "svn checkout --non-interactive $method://$remoteuser@$reposerver/$repopath/$branch $workingdir"
        } # case

        $svn_command_switch = $remoteuser ? {
            false   => "svn switch --non-interactive $method://$reposerver/$repopath/$branch $workingdir",
            default => "svn switch --non-interactive $method://$remoteuser@$reposerver/$repopath/$branch $workingdir"
        } # case

        file { "$workingdir":
            owner   => $remoteuser ? {
                dnsreposvn  => "dnsreposvn",
                false       => "$localuser",
            },
            group   => $remoteuser ? {
                dnsreposvn  => "named",
                false       => "$localuser",
            },
            ensure  => directory,
            recurse => true,
        } # file

        exec {
            "initial checkout":
                command => $svn_command_checkout,
                require => File["$workingdir"],
                before  => Exec["switch"],
                creates => "$workingdir/.svn";
            "switch":
                command => $svn_command_switch,
                require => [File["$workingdir"],Exec["update"]],
                before  => Exec["revert"];
            "update":
                require => File["$workingdir"],
                command =>  "svn update --non-interactive $workingdir";
            "revert":
                command => "svn revert -R $workingdir",
                onlyif  => "svn status --non-interactive $workingdir | egrep '^M|^! |^? ' ";
        } # exec
    } # define checkout
} # class svn
