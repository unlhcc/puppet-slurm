class slurm::params {

    $user      = 'slurm'
    $role      = 'worker'
    $config    = 'puppet:///modules/common/slurm/slurm.conf'
    $cgroup    = 'puppet:///modules/common/slurm/cgroup.conf'
    $gres      = 'puppet:///modules/common/slurm/gres.conf'
    $plugstack = 'puppet:///modules/common/slurm/plugstack.conf'
    $lua       = 'puppet:///modules/common/slurm/lua.d'
    $topology  = 'puppet:///modules/common/slurm/topology.conf'

}
