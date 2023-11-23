package Utils;

our @EXPORT = qw ( print_error print_hash_params array_contains );
use base qw(Exporter);

use strict;

use lib "/home/pi/software";

sub print_error {
  my $str = shift;
  print STDERR localtime() . " $str\n";
}

sub print_hash_params {
  my $ref = shift;
  my $str;
  foreach my $k (keys %$ref) {
    $str .= "$k = " . $ref->{$k} . ", ";
  }
  print_error($str);
}

sub array_contains {
  my @values = @_;
  my $tmp = shift @values;
#  print("Looking for $tmp in ");
#  foreach (@values) {
#    print("$_ ");
#  }
#  print("\n");
  return grep( /^$tmp$/, @values);
}


1;
