# text to speech samples from https://ttsmp3.com/

use strict;
use v5.28;

use lib "/home/pi/software";
use Input;
use Utils;
use Play;
use UserDetails;

use Time::HiRes;
use IPC::MPS;
use IPC::MPS::Event;
use Event;

my %pids;
my $station_num = -1;
my @station_handles = keys %stations;

sub init {
  #`systemctl is-system-running --wait`;                 # wait for system to finish booting
  Input::init_button();
  Play::init();
}

sub next_station {
  $station_num++;
  $station_num = 0 if $station_num == scalar @station_handles;
  Play::stop();
  print_error("playing " . $station_handles[$station_num]);
  snd($pids{"audio"}, "play", $stations{$station_handles[$station_num]});
}

#---------------------------------------------------------------------------------------------------
$pids{"audio"} = spawn {
  receive {
    msg "play" => sub {
      my ($from, $ref) = @_;
      Input::button_led_off();
      eval {Play::play_sample($$ref{"sample"});};
      Input::button_led_on();
      Play::play($$ref{"url"});
    };
  };
};

$pids{"Input"} = spawn {
  receive {
    msg "init" => sub {
      Input::init();
      Knob::set_knob_hue(Play::set_volume());
      snd(0, "input ready");
    };
    msg "start" => sub {
      my ($from, $ref) = @_;
      my $res = Input::monitor();
      Knob::set_knob_hue(Play::volume_up()) if $res eq "vol up";
      Knob::set_knob_hue(Play::volume_down()) if $res eq "vol down";
      snd(0, "change") if $res eq "button";
      snd($pids{"Input"}, "start");
    };
  };
};


init();

receive {
  snd($pids{"Input"}, "init");
  snd($pids{"Input"}, "start");
  msg "input ready" => sub {
    next_station();
  };
  msg "change" => sub {
    next_station();
  };
};
