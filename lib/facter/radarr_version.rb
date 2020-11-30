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
    # radarr_version = Facter::Util::Resolution.exec("wget -q https://github.com/Radarr/Radarr/releases/latest -O - | grep -E \/tag\/ | head -1 | sed 's:^.*/v\([0-9\.]*\)\".*:\1:'")
    # radarr_version = Facter::Util::Resolution.exec("wget -q https://github.com/Radarr/Radarr/releases/latest -O - | grep -E \/tag\/ | grep Pre-Release | head -1 | awk -F '[<>v\"]' '{print $4}'")
    radarr_version = Facter::Util::Resolution.exec('curl -s https://api.github.com/repos/Radarr/Radarr/tags | jq --raw-output ".[0].name"')
    if radarr_version == ''
      nil
    else
      radarr_version
    end
  end
end
