require 'facter'

# Default for non-Linux nodes
#
Facter.add(:radarr_version) do
  setcode do
    nil
  end
end

# Linux
#
Facter.add(:radarr_version) do
  confine kernel: :linux
  setcode do
    if system('which jq > /dev/null 2>&1') && system('which curl > /dev/null 2>&1')
      Facter::Util::Resolution.exec('curl -s https://api.github.com/repos/Radarr/Radarr/releases/latest | jq --raw-output ".name"')
    end
  end
end
