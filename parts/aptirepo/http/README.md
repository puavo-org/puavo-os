# HTTP interface for aptirepo

    curl \
        --form "branch=git-master" \
        --form "changes=@puavo-users_0.6.3~master.de673b79857e9be84eaee9e55ad7cb740224d14e_amd64.changes" \
        --form "file=@puavo-web_0.6.3~master.de673b79857e9be84eaee9e55ad7cb740224d14e_amd64.deb" \
        --form "file=@puavo-rest_0.6.3~master.de673b79857e9be84eaee9e55ad7cb740224d14e_amd64.deb" \
        --form "file=@puavo-rest-bootserver_0.6.3~master.de673b79857e9be84eaee9e55ad7cb740224d14e_amd64.deb" \
        --form "file=@puavo-users_1.0.0+dev1382449832.master.0d5f38c17fc0be7dc47340839821a3b82666e4b9.tar.gz" \
        --form "file=@puavo-users_0.6.3~master.de673b79857e9be84eaee9e55ad7cb740224d14e.dsc" \
        http://aptirepo:8080
