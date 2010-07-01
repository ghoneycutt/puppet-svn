# Class: svn::server
#
# SVN server class
#
# Requires:
#   class apache::ssl
#
class svn::server inherits svn {

    include apache::ssl

    package {
        "mod_dav_svn":
            notify  => Service["apacheService"],
            require => Package["apachePackage"];
        "svnmailer": ;
    } # package

    apache::module {"subversion":
        source  => "puppet:///modules/svn/apache_dav.conf",
    }

    file {
        "/etc/svnmailer/":
            ensure => directory;
        "/etc/svnmailer/svnmailer.conf":
            source => "puppet:///modules/svn/svnmailer.conf";
    } # file

    # Definition: svn::setup
    #
    # setup svn repo
    #
    # Parameters:   
    #   $base       - base directory to hold svn repo
    #   $source     - not currently supported
    #   $hooksource - directory that holds hooks for repository, defaults to "$name/hooks"
    #
    # Actions:
    #   setup svn repo
    #
    # Requires:
    #   $base
    #
    # Sample Usage:
    #    svn::server::setup { "dns":
    #        base => "$svn::repo::base",
    #    }
    #
    define setup ($base, $source = undef, $hooksource = '') {
        $Realhooks = $hooksource ? {
            ''      => "puppet:///modules/svn/$name/hooks",
            default => $hooksource
        } # $Realhooks

        File {
            group => "apache",
            owner => "apache",
            mode  => "755",
        } # File

        file {
            "$base/$name":
                ensure  => directory,
                require => Exec["mkdir $base for $name"];
            "$base/$name/hooks":
                recurse => true,
                require => Exec["create repo $base/$name"],
                source  => "$Realhooks";
        } # file

        exec { "mkdir $base for $name":
            command => "mkdir -p $base",
            creates => "$base";
        } # exec

        if $source {
               # TODO: need to figure this one out.  svn restore or something?
               # whatever it is it needs to be named the same as the exec below
               notify {"source is not yet supported": }
        } else {
            exec { "create repo $base/$name":
                command => "sudo -H -u apache svnadmin create $base/$name",
                path    => "/usr/bin",
                require => [ Package["subversion"], Exec["mkdir $base for $name"] ],
                before  => Class["apache::ssl"],
                creates => "$base/$name/hooks",
            } # exec
        } # fi $source
    } # define setup
} # class svn::server
