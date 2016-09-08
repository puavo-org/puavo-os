Facter.add('localmirror') do
    setcode do
        File.exists?('/opinsys-os/debs/Packages') ? '/opinsys-os/debs' : ''
    end
end

Facter.add('mirror') do
    setcode do
        File.read('/etc/apt/sources.list')
            .match(/^\s*deb\s+http:\/\/(.+)\/debian\/?\s+[a-z]+\s+main.*$/)[1]
    end
end
