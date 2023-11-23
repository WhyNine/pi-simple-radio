package Play;

use v5.28;
use strict;

our @EXPORT = qw ( init play stop volume_up volume_down play_sample set_volume );
use base qw(Exporter);

use lib "/home/pi/software";
use Utils;
use UserDetails;

use List::Util;
use Audio::Play::MPG123;

my $player;
my $volume;

sub init {
  #`bluetoothctl connect 2C:54:BB:2C:79:9B`;
  #sleep 1;
  #`systemctl --user start pulseaudio`;
  set_volume($default_volume);
}

sub play {
  my $url = shift;
  print_error("playing url $url");
  `cvlc --gain 0.2 $url`;
}

sub stop {
  `pkill vlc`;
}

sub set_volume {
  $volume = shift || $volume;
  print_error("volume set to $volume");
  `amixer set Master $volume%`;
  return $volume;
}

sub volume_up {
  return set_volume(List::Util::min(100, $volume + 3));
}

sub volume_down {
  return set_volume(List::Util::max(5, $volume - 3));
}

sub play_sample {
  my $sample = shift;
  $sample = "/home/pi/software/samples/" . $sample;
  $player = new Audio::Play::MPG123;
  $player->load($sample);
  print_error("Playing sample $sample");
  #$player->poll(1) until $player->state == 0;
}


1;
