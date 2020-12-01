#
class radarr::install {


# Get the latest tag (replacves the custom fact"
  $bindir = '/opt/puppetlabs/puppet/bin'
  $curl   = "${bindir}/curl"
  $jq     = '/usr/bin/jq'

  $tags_url        = 'https://api.github.com/repos/Radarr/Radarr/tags'
  $jq_version      = "${jq} --raw-output '.[0].name'"
  $package_version = chomp(inline_template("<%= `${curl} -s ${tags_url} | ${jq_version}` %>"))
  unless $package_version =~ String[1] {
    fail ("radarr version is '${package_version}'")
  }

  case $facts['os']['architecture'] {
    'amd64': {
      $arch = 'linux.core.x64'
    }
    default: {
    fail("Architecture ${facts['os']['architecture']} is not supported")
    }
  }

# Select the download url of the package that matches the arch above
  $latest_url      = 'https://api.github.com/repos/Radarr/Radarr/releases/latest'
  $jq_url          = "${jq} --raw-output '.assets[].browser_download_url'"
  $package_source  = chomp(inline_template("<%= `${curl} -s ${latest_url} | ${jq_url} | grep ${arch}` %>"))
  unless $package_source =~ String[1] {
    fail ("Unable to get download url for Radarr version '${package_version}'")
  }

# get the archive name and strin gthe tar.gz suffix
  $archive_name    = basename($package_source)
  $package_name    = basename($archive_name,'.tar.gz')

  $install_path    = $::radarr::install_path
  $extract_dir     = "${install_path}/${package_name}"
  $creates         = "${extract_dir}/Radarr"
  $link            = "${install_path}/Radarr"
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
      notify       => Service['radarr.service']
    }
    file { $link:
      ensure    => 'link',
      target    => $creates,
      subscribe => Archive[$archive_name],
    }
    exec {'radarr_tidy':
      cwd         => $install_path,
      path        => '/usr/sbin:/usr/bin:/sbin:/bin:',
      command     => "ls -dtr ${link}[.-]* | head -n -${radarr::keep} | xargs rm -rf",
      refreshonly => true,
      subscribe   => Archive[$archive_name],
    }
  }
}
