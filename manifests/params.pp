#
# Class: slurm::params
#

class slurm::params {

    $user                  = 'slurm'
    $config                = 'puppet:///modules/common/slurm/slurm.conf'
    $cgroup                = 'puppet:///modules/common/slurm/cgroup.conf'
    $gres                  = 'puppet:///modules/common/slurm/gres.conf'
    $plugstack             = 'puppet:///modules/common/slurm/plugstack.conf'
    $job_submit_lua        = 'puppet:///modules/common/slurm/job_submit.lua'
    $lua                   = 'puppet:///modules/common/slurm/lua.d'
    $topology              = 'puppet:///modules/common/slurm/topology.conf'
    $slurmdbd_storagehost  = 'localhost'
    $slurmdbd_storageuser  = 'slurm'
    $slurmdbd_storagepass  = ''
    $slurmdbd_storageloc   = 'slurm_acct_db'
    $slurmd_service_dropin = 'puppet:///modules/common/slurm/slurmd.service.d.dropin.conf'

}
