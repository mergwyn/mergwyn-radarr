# @summary Download github release and extract to install directory
#
class radarr::install {

  if $radarr::package_manage {
    case $facts['os']['architecture'] {
      'amd64': { $edition = 'linux-core-x64' }
      default: { fail("Architecture ${facts['os']['architecture']} is not supported") }
    }

    $archive_name = "/Radarr.latest.${edition}.tar.gz"
    $archive_path = "${::puppet_vardir}/${archive_name}"
    $install_path = $::radarr::install_path
    $creates      = "${install_path}/Radarr"

    githubreleases_download { $archive_path:
      author            => 'Radarr',
      repository        => 'Radarr',
      asset             => true,
      asset_filepattern => $edition,
    }
    -> archive { $archive_name:
      source       => $archive_path,
      extract      => true,
      extract_path => $install_path,
      creates      => $creates,
      cleanup      => false,
      user         => $::radarr::user,
      group        => $::radarr::group,
      notify       => Service['radarr.service'],
      require      => Githubreleases_download[$archive_path],
      refreshonly  => true,
    }
  }
}
