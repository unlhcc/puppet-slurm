#
# Class: slurm
#

class slurm (
    $user                  = $slurm::params::user,
    $role                  = $slurm::params::role,
    $config                = $slurm::params::config,
    $cgroup                = $slurm::params::cgroup,
    $gres                  = $slurm::params::gres,
    $plugstack             = $slurm::params::plugstack,
    $lua                   = $slurm::params::lua,
    $topology              = $slurm::params::topology,
    $slurmd_service_dropin = $slurm::params::slurmd_service_dropin,
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
        source  => $cgroup,
    }

    file { '/etc/slurm/topology.conf':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => $topology,
    }

    user { "slurm":
        name       => $user,
        ensure     => present,
        system     => true,
        managehome => false,
        shell      => '/sbin/nologin',
        # Debian reserved uid/gid
        # http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=444412
        uid        => 64030,
        gid        => "nobody",
    }

    package { 'slurm':
        ensure => present,
    }

    package { 'slurm-libpmi':
        ensure => present,
    }

    ########################################################

    # SLURM service ########################################
    # FIXME: Improve this block
    if $role == 'compute' {

        file { '/etc/slurm/plugstack.conf':
            source  => $plugstack,
        }

        file { '/etc/slurm/lua.d':
            source  => $lua,
            recurse => true,
            purge   => true,
        }

        if $gres {
            file { '/etc/slurm/gres.conf':
                source  => $gres,
                notify  => Service['slurmd'],
            }
        }

        package { 'slurm-slurmd':
            ensure => present,
        }

        # Packages needed for SLURM Lua plugins
        package { 'lua-posix':
            ensure => present,
        }
        package { 'lua-linuxsys':
            ensure => present,
        }
        package { 'slurm-spank-plugins-lua':
            ensure  => present,
            # This package runs the Lua plugins
            require => [ Package['lua-posix', 'lua-linuxsys'],
                         File['/etc/slurm/lua.d'], ],
        }

        # Running on compute nodes/workers
        service { 'slurmd':
            ensure    => running,
            enable    => true,
            require   => Package['slurm-slurmd'],
            subscribe => [ File['/etc/slurm/slurm.conf'],
                           File['/etc/slurm/cgroup.conf'],
                           File['/etc/slurm/plugstack.conf'], ],
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
            source  => $slurmd_service_dropin,
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

        # Running on controller
        service { 'slurmdbd':
            ensure    => running,
            enable    => true,
            require   => Package['slurm-slurmdbd'],
        }

        service { 'slurmctld':
            ensure    => running,
            enable    => true,
            require   => [ Service['slurmdbd'],
                           Package['slurm-slurmctld'], ],
            subscribe => [ File['/etc/slurm/slurm.conf'],
                           File['/etc/slurm/cgroup.conf'],
                           File['/etc/slurm/topology.conf'], ],
        }
    } else {
        # Installed and configured, but not running on other roles
    }

}
