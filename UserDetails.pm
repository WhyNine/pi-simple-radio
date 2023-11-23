package UserDetails;

our @EXPORT = qw ( $default_volume %stations $led_pin_no $button_pin_no );
use base qw(Exporter);
use strict;

use lib "/home/pi/doorbell";
use Utils;

use YAMC;

my $yamc = new YAMC();
$yamc->fileName('/home/pi/software/UserDetails.yml');

# This YAML file is expected to contain:
# default-volume: <0 to 100>
# radio:
#   label:
#     name: <radio station name>
#     url: <url to play from
#     sample: <audio filename with station title>
# pins:
#   led: <pin number for led in button>
#   button: <pin number for button>

my $hash = $yamc->Read();
my %settings = %$hash;

our $default_volume = $settings{"default-volume"};
$default_volume = 50 unless $default_volume;

$hash = $settings{"radio"};
our %stations = %$hash;

$hash = $settings{"pins"};
our $led_pin_no = $$hash{"led"};
our $button_pin_no = $$hash{"button"};

1;
