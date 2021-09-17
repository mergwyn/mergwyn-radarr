# @summary install package from github
class radarr::install {

  if $radarr::package_manage {

    if ! defined( Package[curl] ) { package { 'curl': ensure=>installed; } }
    if ! defined( Package[jq] )   { package { 'jq':   ensure=>installed; } }

# Only execute if radarr version has already been defined (first run may need the
# packages above to be installed

    if $::radarr_version {
      # Make sure version has is a string with at least 1 char
      unless $::radarr_version =~ String[1] {
        fail ("radarr_version cannot be an empty string '${::radarr_version}'")
      }
      case $facts['os']['architecture'] {
        'amd64': { $edition = 'linux-core-x64' }
        default: { fail("Architecture ${facts['os']['architecture']} is not supported") }
      }
# Radarr.master.3.2.2.5080.linux-core-arm64.tar.gz
# https://github.com/Radarr/Radarr/releases/download/v3.2.2.5080/Radarr.master.3.2.2.5080.linux-core-arm64.tar.gz


      $short_version   = $::radarr_version[1,-1]
      $package_version = $::radarr_version
      $install_path    = $::radarr::install_path
      $package_name    = 'Radarr.master'
      $extract_dir     = "${install_path}/Radarr-${package_version}"
      $creates         = "${extract_dir}/Radarr"
      $link            = "${install_path}/Radarr"
      $repository_url  = 'https://github.com/Radarr/Radarr/releases/download'
      $archive_name    = "${package_name}.${short_version}.${edition}.tar.gz"
      $package_source  = "${repository_url}/${package_version}/${archive_name}"
      $archive_path    = "${install_path}/${archive_name}"

      if $radarr::package_manage {

        file { $extract_dir:
          ensure => directory,
          owner  => $::radarr::user,
          group  => $::radarr::group,
        }

        archive { $archive_name:
          path         => $archive_path,
          source       => $package_source,
          extract      => true,
          extract_path => $extract_dir,
          creates      => $creates,
          cleanup      => true,
          user         => $::radarr::user,
          group        => $::radarr::group,
          #TODO reference to mono
          #require      => Class['mono'],
          notify       => Service['radarr.service'],
        }
        file { $link:
          ensure    => 'link',
          target    => $creates,
          subscribe => Archive[$archive_name],
        }
        exec {'radarr_tidy':
          cwd         => $install_path,
          path        => '/usr/sbin:/usr/bin:/sbin:/bin:',
          command     => "ls -dtr ${link}-* | head -n -${radarr::keep} | xargs rm -rf",
          #onlyif      => "test $(ls -d ${link}-* | wc -l) -gt ${radarr::keep}",
          refreshonly => true,
          subscribe   => Archive[$archive_name],
        }
      }
    }
  }
}
