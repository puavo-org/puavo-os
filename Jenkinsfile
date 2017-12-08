pipeline {
  agent {
    docker {
      image 'debian:stretch'
      // XXX could you do most operations as normal user?
      args '-u root'
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
        withCredentials([file(credentialsId: 'dput.cf',
                              variable: 'DPUT_CONFIG_FILE')]) {
          sh 'install -o root -g root -m 644 "$DPUT_CONFIG_FILE" /etc/dput.cf'
        }
        withCredentials([file(credentialsId: 'ssh_known_hosts',
                              variable: 'SSH_KNOWN_HOSTS')]) {
          sh '''
            mkdir -m 700 -p ~/.ssh
            cp -p "$SSH_KNOWN_HOSTS" ~/.ssh/known_hosts
          '''
        }
        withCredentials([sshUserPrivateKey(credentialsId: 'puavo-deb-upload',
                                           keyFileVariable: 'ID_RSA',
                                           passphraseVariable: '',
                                           usernameVariable: '')]) {
          sh 'cp -p "$ID_RSA" ~/.ssh/id_rsa'
        }
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
