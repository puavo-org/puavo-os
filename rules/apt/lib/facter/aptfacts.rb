Facter.add('mirror') do
    setcode do
        File.read('/etc/apt/sources.list')
            .match(/^\s*deb\s+http:\/\/(.+)\/debian\/?\s+[a-z]+\s+main.*$/)[1]
    end
end
