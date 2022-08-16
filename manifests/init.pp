#
# Class: slurm
#

class slurm (
    String $user                                 = $slurm::params::user,
    Enum['compute', 'controller', 'other'] $role = 'other',
    String $config                               = $slurm::params::config,
    String $cgroup                               = $slurm::params::cgroup,
    String $gres                                 = $slurm::params::gres,
    String $plugstack                            = $slurm::params::plugstack,
    String $job_submit_lua                       = $slurm::params::job_submit_lua,
    String $lua                                  = $slurm::params::lua,
    String $topology                             = $slurm::params::topology,
    String $slurmdbd_storagehost                 = $slurm::params::slurmdbd_storagehost,
    String $slurmdbd_storageuser                 = $slurm::params::slurmdbd_storageuser,
    String $slurmdbd_storagepass                 = $slurm::params::slurmdbd_storagepass,
    String $slurmdbd_storageloc                  = $slurm::params::slurmdbd_storageloc,
    String $slurmd_service_dropin                = $slurm::params::slurmd_service_dropin,
    Boolean $install_contribs                    = $slurm::params::install_contribs,
  ) inherits slurm::params {

    ########################################################

    file { '/etc/slurm':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/slurm/slurm.conf':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => $config,
    }

    file { '/etc/slurm/cgroup.conf':
        source => $cgroup,
    }

    file { '/etc/slurm/topology.conf':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => $topology,
    }

    user { 'slurm':
        ensure     => present,
        name       => $user,
        system     => true,
        managehome => false,
        shell      => '/sbin/nologin',
        # Debian reserved uid/gid
        # http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=444412
        uid        => 64030,
        gid        => 'nobody',
    }

    package { 'slurm':
        ensure => present,
    }

    package { 'slurm-libpmi':
        ensure => present,
    }

    if $install_contribs {

        # slurm-contribs perl scripts "use" but have no rpm requires for
        # slurm-perlapi, install the package here to meet the dependency.
        package { 'slurm-perlapi':
            ensure => present,
        }

        package { 'slurm-contribs':
            ensure => present,
        }

    }

    ########################################################

    # SLURM service ########################################
    # FIXME: Improve this block
    if $role == 'compute' {

        file { '/etc/slurm/plugstack.conf':
            source => $plugstack,
        }

        file { '/etc/slurm/lua.d':
            source  => $lua,
            recurse => true,
            purge   => true,
            force   => true,
        }

        if $gres {
            file { '/etc/slurm/gres.conf':
                source => $gres,
                notify => Service['slurmd'],
            }
        }

        package { 'slurm-slurmd':
            ensure => present,
        }

        # Packages needed for SLURM Lua plugins
        if ! defined(Package['lua-posix']) {
            package { 'lua-posix':
                ensure => present,
            }
        }
        package { 'lua-linuxsys':
            ensure => present,
        }
        package { 'slurm-spank-lua':
            ensure  => present,
            # This package runs the Lua plugins
            require => [
                Package['lua-posix', 'lua-linuxsys'],
                File['/etc/slurm/lua.d'],
            ],
        }

        # Running on compute nodes/workers
        service { 'slurmd':
            ensure    => running,
            enable    => true,
            require   => Package['slurm-slurmd'],
            subscribe => [
                File['/etc/slurm/slurm.conf'],
                File['/etc/slurm/cgroup.conf'],
                File['/etc/slurm/plugstack.conf'],
            ],
        }

        file { '/etc/systemd/system/slurmd.service.d':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }

        file { '/etc/systemd/system/slurmd.service.d/dropin.conf':
            ensure => 'file',
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => $slurmd_service_dropin,
        }

        exec { '/usr/bin/systemctl daemon-reload':
            refreshonly => true,
            subscribe   => File['/etc/systemd/system/slurmd.service.d/dropin.conf'],
            notify      => Service['slurmd'],
        }

    } elsif $role == 'controller' {

        package { 'slurm-slurmdbd':
            ensure => present,
        }

        package { 'slurm-slurmctld':
            ensure => present,
        }

        # dir needed by slurmdbd and slurmctld
        file { '/var/log/slurm':
            ensure => 'directory',
            owner  => 'slurm',
            group  => 'nobody',
            mode   => '0755',
        }

        # files/dirs needed by slurmdbd
        $slurmdbd_parameters = {
            storagehost => $slurmdbd_storagehost,
            storageuser => $slurmdbd_storageuser,
            storagepass => $slurmdbd_storagepass,
            storageloc  => $slurmdbd_storageloc,
        }

        file { '/etc/slurm/slurmdbd.conf':
            ensure  => 'file',
            owner   => 'slurm',
            group   => 'nobody',
            mode    => '0600',
            content => epp('common/slurm/slurmdbd.conf.epp',
                            $slurmdbd_parameters),
        }

        file { '/var/log/slurm/archive':
            ensure => 'directory',
            owner  => 'slurm',
            group  => 'nobody',
            mode   => '0755',
        }

        file { '/var/log/slurm/slurmdbd.log':
            ensure => 'file',
            owner  => 'slurm',
            group  => 'nobody',
            mode   => '0600',
        }

        # Running on controller host
        service { 'slurmdbd':
            ensure  => running,
            enable  => true,
            require => Package['slurm-slurmdbd'],
        }

        # files/dirs needed by slurmctld
        file { '/etc/slurm/job_submit.lua':
            ensure => 'file',
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => $job_submit_lua,
        }

        file { '/var/log/slurm/slurmctld.log':
            ensure => 'file',
            owner  => 'slurm',
            group  => 'nobody',
            mode   => '0600',
        }

        file { '/var/spool/slurmd':
            ensure => 'directory',
            owner  => 'slurm',
            group  => 'nobody',
            mode   => '0700',
        }

        service { 'slurmctld':
            ensure    => running,
            enable    => true,
            require   => [
                Service['slurmdbd'],
                Package['slurm-slurmctld'],
            ],
            subscribe => [
                File['/etc/slurm/slurm.conf'],
                File['/etc/slurm/cgroup.conf'],
                File['/etc/slurm/topology.conf'],
            ],
        }
    } elsif $role == 'other' {
        # Installed and configured, but not running on other roles
    }

}
