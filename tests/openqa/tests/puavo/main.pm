use Mojo::Base -strict;
use autotest;
use puavo_debian;
use testapi;

testapi::set_distribution(puavo_debian->new);

my $schedule = get_var('SCHEDULE');
unless ($schedule) {
  die 'No schedule provided.  Please set the SCHEDULE variable with'
        . ' a comma-separated list of test modules.';
}

# A test schedule is provided (comma-separated list), load tests accordingly.
for my $module (split /\s*,\s*/, $schedule) {
  autotest::loadtest "tests/${module}.pm";
}

1;
