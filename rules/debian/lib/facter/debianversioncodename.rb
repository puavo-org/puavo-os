Facter.add('debianversioncodename') do
    lsbdistcodename = Facter.value('lsbdistcodename')
    if lsbdistcodename != 'n/a'
	debianversioncodename = lsbdistcodename
    else
	debianversioncodename = \
	    Facter.value('os')['release']['major'].match('^(.*?)/.*$')[1] rescue nil
        if debianversioncodename.nil? || debianversioncodename.empty? then
	    debianversioncodename = 'n/a'
        end
    end

    setcode { debianversioncodename }
end
