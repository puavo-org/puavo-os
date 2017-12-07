pipeline {
  agent {
    docker {
      image 'debian:stretch'
      // XXX could you do most operations as normal user?
      args '-u root'
    }
  }

  stages {
    stage('Prepare for image build') {
      steps {
        sh '''
          apt-get update
          apt-get install -y devscripts dpkg-dev make
          make setup-buildhost
        '''
      }
    }

    stage('Bootstrap image') {
      steps {
        sh 'make rootfs-debootstrap'
      }
    }

    stage('Build and configure image') {
      steps {
        sh 'make rootfs-update'
      }
    }

    stage('Make the squashfs image') {
      steps {
        sh 'make release_name=Jenkinsbuild-$(date +%s) rootfs-image'
      }
    }

    stage('Test') {
      steps {
        sh 'echo XXX make test the image maybe'
      }
    }

    stage('Upload') {
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
          sh 'echo XXX could maybe upload the built debian packages'
          sh 'echo XXX could maybe upload the image somewhere'
        }
      }
    }
  }
}
