package puavo_debian;
use base 'distribution';

sub init {
  my ($self) = @_;
  $self->add_console('ssh-serial', 'sshSerial',
    { hostname => '10.0.2.5', username => 'debian', password => 'puavo' }
  );
}

1;
