pipeline {
  agent {
    docker {
      image 'debian:stretch'
      // XXX could you do most operations as normal user?
      args '-u root --mount type=bind,source=/etc/jenkins-docker-config,destination=/etc/jenkins-docker-config,readonly'
    }
  }

  stages {
    stage('Prepare for build') {
      steps {
        sh '''
          apt-get update
          apt-get -y dist-upgrade
          apt-get install -y devscripts dpkg-dev make
          make setup-buildhost
        '''
      }
    }

    stage('Install deb-package build dependencies') {
      steps { sh 'make install-build-deps' }
    }

    stage('Build puavo-os deb-packages') {
      steps { sh 'make build-debs-parts' }
    }

    stage('Build custom deb-packages used in puavo-os') {
      steps { sh 'make build-debs-ports' }
    }

    stage('Upload deb-packages') {
      steps {
        sh '''
          install -o root -g root -m 644 /etc/jenkins-docker-config/dput.cf \
            /etc/dput.cf
          install -o root -g root -m 644 \
            /etc/jenkins-docker-config/ssh_known_hosts \
            /etc/ssh/ssh_known_hosts
          install -d -o root -g root -m 700 ~/.ssh
          install -o root -g root -m 600 \
            /etc/jenkins-docker-config/sshkey_puavo_deb_upload \
            ~/.ssh/id_rsa
        '''

        sh 'make upload-debs'
      }
    }

    stage('Bootstrap image') {
      steps { sh 'make rootfs-debootstrap' }
    }

    stage('Build and configure image') {
      steps { sh 'make rootfs-update' }
    }

    stage('Make the squashfs image') {
      steps { sh 'make release_name="Jenkinsbuild-$(date +%s)" rootfs-image' }
    }

    stage('Test') {
      steps { sh 'echo XXX make test the image maybe' }
    }

    stage('Upload image') {
      steps { sh 'echo XXX maybe upload image here somehow somewhere' }
    }
  }
}
