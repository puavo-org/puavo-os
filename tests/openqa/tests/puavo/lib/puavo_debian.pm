package puavo_debian;
use base 'distribution';

sub init {
  my ($self) = @_;
  $self->{serial_term_prompt} = 'debian@debian:~$';
  $self->add_console('ssh-serial', 'sshSerial', {
      hostname           => '10.0.2.5',
      username           => 'debian',
      password           => 'puavo',
    }
  );
}

1;
