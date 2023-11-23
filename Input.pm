package Input;

use v5.28;
use strict;

our @EXPORT = qw ( init monitor button_led_off button_led_on init_button );
use base qw(Exporter);

use lib "/home/pi/software";
use Utils;
use Knob;
use UserDetails;

use RPi::Pin;
use RPi::Const qw(:all);
use Time::HiRes qw(time);

my $led_pin;
my $button_pin;
my $knob_value = 0;


# Set knob colour depending on volume. Use Convert::Color

# return "button", "vol up" or "vol down"
sub monitor {
  my $last_knob_value = $knob_value;
  my $button_down = ($button_pin->read == 0);
  while (1) {
    $knob_value = read_rotary_encoder();
    #print_error("knob value = $knob_value");
    if ($knob_value != $last_knob_value) {
      if ($knob_value > $last_knob_value) {
        print_error("knob up");
        return "vol up";
      }
      if ($knob_value < $last_knob_value) {
        print_error("knob down");
        return "vol down";
      }
    }
    if ((!$button_down) && ($button_pin->read == 0)) {
      print_error("button press");
      return "button";
    }
    $button_down = ($button_pin->read == 0);
    time.sleep(0.1);
  }
}

sub button_led_on {
  $led_pin->write(1);
}

sub button_led_off {
  $led_pin->write(0);
}

sub init_button {
  $led_pin = RPi::Pin->new($led_pin_no);
  $led_pin->mode(OUTPUT);
  button_led_on();
}

sub init {
  $button_pin = RPi::Pin->new($button_pin_no);
  $button_pin->mode(INPUT);
  $button_pin->pull(PUD_UP);
  init_knob();
}


1;
