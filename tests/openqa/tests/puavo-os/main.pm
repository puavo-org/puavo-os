use Mojo::Base -strict;
use testapi;
use autotest;

# If a test schedule is provided (comma-separated list), load tests accordingly.
# Otherwise throw an error since no schedule was specified.
if (my $schedule = get_var('SCHEDULE')) {
    for my $module (split /\s*,\s*/, $schedule) {
        next unless $module; # Skip empty
        autotest::loadtest "tests/$module.pm";
    }
} else {
    die "No schedule provided. Please set the SCHEDULE variable with a comma-separated list of test modules.";
}

1;
