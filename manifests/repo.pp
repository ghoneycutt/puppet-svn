# Class: svn::repo
#
# Do everything required to create repo for the software collection
#
# Requires:
#   class generic
#   class svn::server
#
class svn::repo {

    include generic
    include svn::server

    $base = "/opt/$lsbProvider/svn/"

    file { "$base":
        ensure  => directory,
        require => Class["generic"],
    } # file

} # class svn::repo
