#
# Class: slurm
#

class slurm (
  $user      = $slurm::params::user,
  $role      = $slurm::params::role,
  $config    = $slurm::params::config,
  $cgroup    = $slurm::params::cgroup,
  $gres      = $slurm::params::gres,
  $cgconfig  = $slurm::params::cgconfig,
  $sysconfig = $slurm::params::sysconfig,
  $plugstack = $slurm::params::plugstack,
  $lua       = $slurm::params::lua,
  $topology  = $slurm::params::topology,
  ) inherits slurm::params {

    package { 'slurm': ensure => present }
    package { 'slurm-munge': ensure => present }

    # Packages needed for SLURM Lua plugins
    package { 'lua-posix':               ensure => present }
    package { 'lua-linuxsys':            ensure => present }
    package { 'slurm-spank-plugins-lua':
        ensure  => present,
        # This package runs the Lua plugins
        require => [ Package['lua-posix', 'lua-linuxsys'],
                     File['/etc/slurm/lua.d'], ],
    }

    # SLURM service ########################################
    # FIXME: Improve this block
    if $role == 'worker' {
        # Running on workers
        service { 'slurm':
            ensure  => running,
            enable  => true,
            require => Package['slurm'],
        }
    } else {
        # Installed and configured, but not running on other roles
        service { 'slurm':
            #ensure  => running,
            #enable  => true,
            require => Package['slurm'],
        }
    }
    ########################################################

    file { '/etc/slurm/slurm.conf':
        source  => $config,
        require => Package['slurm'],
        notify  => Service['slurm'],
    }

    file { '/etc/slurm/cgroup.conf':
        source  => $cgroup,
        require => Package['slurm'],
        notify  => Service['slurm'],
    }

    if $gres {
        file { '/etc/slurm/gres.conf':
            source  => $gres,
            require => Package['slurm'],
            notify  => Service['slurm'],
        }
    }

    file { '/etc/slurm/topology.conf':
        source  => $topology,
        require => Package['slurm'],
        notify  => Service['slurm'],
    }

    file { '/etc/slurm/plugstack.conf':
        source  => $plugstack,
    }

    file { '/etc/slurm/lua.d':
        source  => $lua,
        recurse => true,
        purge   => true,
    }

    file { '/etc/sysconfig/slurm':
        source  => $sysconfig,
        require => Package['slurm'],
        notify  => Service['slurm'],
    }

    # cgroups config for workers ###########################
    if $role == 'worker' {
        package { 'libcgroup': ensure => present }

        service { 'cgconfig':
            ensure  => running,
            enable  => true,
            require => Package['libcgroup'],
        }

        file { '/etc/cgconfig.conf':
            source  => $cgconfig,
            require => Package['libcgroup'],
            notify  => Service['cgconfig'],
        }
    }
    ########################################################

}
