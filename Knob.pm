package Knob;

use v5.28;
use strict;

our @EXPORT = qw ( init_knob set_knob_hue read_rotary_encoder );
use base qw(Exporter);

use lib "/home/pi/software";
use Utils;
use UserDetails;
use REGS;

use Time::HiRes qw(time);
use Device::I2C;
use IO::File;
use Convert::Color;

my $volume_i2c_addr = 0x0F;
my $volume_device;

# definitions for volume knob

# These values encode our desired pin function: IO, ADC, PWM
# alongside the GPIO MODE for that port and pin (section 8.1)
# the 5th bit additionally encodes the default output state
my $PIN_MODE_IO = 0b00000;   # General IO mode, IE: not ADC or PWM
my $PIN_MODE_QB = 0b00000;   # Output, Quasi-Bidirectional mode
my $PIN_MODE_PP = 0b00001;   # Output, Push-Pull mode
my $PIN_MODE_IN = 0b00010;   # Input-only (high-impedance)
my $PIN_MODE_PU = 0b10000;   # Input (with pull-up)
my $PIN_MODE_OD = 0b00011;   # Output, Open-Drain mode
my $PIN_MODE_PWM = 0b00101;  # PWM, Output, Push-Pull mode
my $PIN_MODE_ADC = 0b01010;  # ADC, Input-only (high-impedance)
my @MODE_NAMES = ("IO", "PWM", "ADC");
my @GPIO_NAMES = ("QB", "PP", "IN", "OD");
my @STATE_NAMES = ("LOW", "HIGH");
my $KNOB_A = 12;
my $KNOB_B = 3;
my $KNOB_C = 11;
my $LED_RED = 1;
my $LED_GREEN = 7;
my $LED_BLUE = 2;
my %colours = (RED =>     [255, 0, 0],
               GREEN =>   [0, 255, 0],
               YELLOW =>  [255, 255, 0],
               BLUE =>    [0, 0, 255],
               PURPLE =>  [255, 0, 255],
               CYAN =>    [0, 255, 255],
               WHITE =>   [255, 255, 255],
               OFF =>     [0, 0, 0]
);

my @pins;
my @regs_pwml;
my @regs_pwmh;
my @regs_m1;
my @regs_m2;
my @regs_p;
my @regs_ps;
my @regs_piocon;
my @encoder_last = (0, 0, 0, 0);
my @encoder_offset = (0, 0, 0, 0);
my $knob = 0;         # value read from rotary encoder

sub read_i2c_byte {
  my ($reg) = @_;
  $volume_device->selectDevice($volume_i2c_addr);
  my $tmp = $volume_device->readByteData($reg);
  #printf("read %02X from %02X\n", $tmp, $reg);
  return $tmp;
}

sub write_i2c_byte {
  my ($reg, $data) = @_;
  #printf("writing %02X to %02X\n", $data, $reg);
  $volume_device->selectDevice($volume_i2c_addr);
  $volume_device->writeByteData($reg, $data & 0xff);
}

sub write_i2c_block {
  my ($reg, $data_ref) = @_;
  my @data = @$data_ref;
  foreach my $i (0 .. scalar(@data) - 1) {
    write_i2c_byte($reg + $i, $data[$i]);
  }
}

# Enable the analog to digital converter."""
sub enable_adc {
  my $pin = shift;
  set_bit($REGS::REG_ADCCON1, 0);
  $pin->{adc_enabled} = 1;
}

# Returns the specified bit (nth position from right) from a register."""
sub get_bit {
  my ($reg, $bit) = @_;
  return read_i2c_byte($reg) & (1 << $bit);
}

# Set the specified bits (using a mask) in a register.
sub set_bits {   # reg, bits
  my ($reg, $bits) = @_;
  #printf("set bits %02X to %02X\n", $bits, $reg);
  if (array_contains($reg, @REGS::BIT_ADDRESSED_REGS)) {
    for my $bit (0 .. 7) {
      if ($bits & (1 << $bit)) {
        write_i2c_byte($reg, 0b1000 | ($bit & 0b111));
      }
    }
  } else {
    if ($bits > 255) {
      print_error("Trying to set non-existent bits: $bits");
      return;
    }
    my $value = read_i2c_byte($reg);
    time.sleep(0.010);
    write_i2c_byte($reg, $value | $bits);
    #print("Check: "); read_i2c_byte($reg);
  }
}

# Set the specified bit (nth position from right) in a register.
sub set_bit {
  my ($reg, $bit) = @_;
  #printf("set bit $bit in %02X\n", $reg);
  set_bits($reg, (1 << $bit));
}

# Clear the specified bits (using a mask) in a register.
sub clr_bits {
  my ($reg, $bits) = @_;
  if (array_contains($reg, @REGS::BIT_ADDRESSED_REGS)) {
    #print("clear bits $bits from bit addressed $reg\n");
    for my $bit (0 .. 7) {
      if ($bits & (1 << $bit)) {
        write_i2c_byte($reg, 0b0000 | ($bit & 0b111));
      }
    }
  } else {
    #print("clear bits $bits from $reg\n");
    if ($bits > 255) {
      print_error("Trying to slear non-existent bits: $bits");
      return;
    }
    my $value = read_i2c_byte($reg);
    time.sleep(0.010);
    write_i2c_byte($reg, $value & ~$bits);
    #print("Check: "); read_i2c_byte($reg);
  }
}

# Clear the specified bit (nth position from right) in a register.
sub clr_bit {
  my ($reg, $bit) = @_;
  #printf("clear bit $bit in %02X\n", $reg);
  clr_bits($reg, (1 << $bit));
}

# Toggle one register bit on/off."""
sub change_bit {
  my ($reg, $bit, $state) = @_;
  if ($state) {
    set_bit($reg, $bit)
  } else {
    clr_bit($reg, $bit)
  }
}

# Set a pin output mode.
# Note mode is one of the supplied IN, OUT, PWM or ADC constants
sub set_mode {
  my ($pin, $mode, $schmitt_trigger, $invert) = @_;
  $schmitt_trigger = 0 if not defined $schmitt_trigger;
  $invert = 0 if not defined $invert;
  my $io_pin = $pins[$pin];
  #print_hash_params($io_pin);
  return if ($$io_pin{mode} == $mode);

  my $gpio_mode = $mode & 0b11;
  my $io_mode = ($mode >> 2) & 0b11;
  my $initial_state = $mode >> 4;

  my $ref = $$io_pin{type};
  if (($io_mode != $PIN_MODE_IO) && (not array_contains($mode, @$ref))) {
    print_error("Pin $pin does not support " . $MODE_NAMES[$io_mode]);
    return;
  }

  $$io_pin{mode} = $mode;
  #print_error("Setting pin $pin to mode $MODE_NAMES[$io_mode] $GPIO_NAMES[$gpio_mode], state: $STATE_NAMES[$initial_state]");

  if ($mode == $PIN_MODE_PWM) {
    set_bit($regs_piocon[$io_pin->{reg_iopwm}], $io_pin->{bit_iopwm});
    if ($io_pin->{pwm_module} == 0) {                   # Only module 0's outputs can be inverted
      change_bit($REGS::REG_PNP, $io_pin->{bit_iopwm}, $invert);
    }
    set_bit($REGS::REG_PWMCON0, 7);                           # Set PWMRUN bit
  } else {
    if ($mode == $PIN_MODE_ADC) {
      enable_adc($io_pin);
    } else {
      if (array_contains($PIN_MODE_PWM, @{$io_pin->{type}})) {
        clr_bit($regs_piocon[$io_pin->{reg_iopwm}], $io_pin->{bit_iopwm});
      }
    }
  }

  my $pm1 = read_i2c_byte($regs_m1[$io_pin->{port}]);
  my $pm2 = read_i2c_byte($regs_m2[$io_pin->{port}]);

  # Clear the pm1 and pm2 bits
  $pm1 = $pm1 & (255 - (1 << $io_pin->{pin}));
  $pm2 = $pm2 & (255 - (1 << $io_pin->{pin}));

  # Set the new pm1 and pm2 bits according to our gpio_mode
  $pm1 = $pm1 | (($gpio_mode >> 1) << $io_pin->{pin});
  $pm2 = $pm2 | (($gpio_mode & 0b1) << $io_pin->{pin});

  write_i2c_byte($regs_m1[$io_pin->{port}], $pm1);
  write_i2c_byte($regs_m2[$io_pin->{port}], $pm2);

  # Set up Schmitt trigger mode on inputs
  if (array_contains($mode , [$PIN_MODE_PU, $PIN_MODE_IN])) {
    change_bit($regs_ps[$io_pin->{port}], $io_pin->{pin}, $schmitt_trigger);
  }

  # If pin is a bsic output, invert its initial state
  if (($mode == $PIN_MODE_PP) and $invert) {
    $initial_state = not $initial_state;
    $io_pin->{inv_output} = 1;
  } else {
    $io_pin->{inv_output} = 0;
  }

  # 5th bit of mode encodes default output pin state
  write_i2c_byte($regs_p[$io_pin->{port}], ($initial_state << 3) | $io_pin->{pin});
}

sub pwm_loading {
  my $pwm_module = shift;
  $pwm_module = 0 if not defined $pwm_module;
  return get_bit($REGS::REG_PWMCON0, 6);
}

# Load new period and duty registers into buffer
sub pwm_load {
  my ($pwm_module, $wait_for_load) = @_;
  $pwm_module = 0 if not defined $pwm_module;
  $wait_for_load = 1 if not defined $wait_for_load;
  #print_error("pwm load module $pwm_module");
  my $t_start = time();
  set_bit($REGS::REG_PWMCON0, 6);  # Set the "LOAD" bit of PWMCON0
  if ($wait_for_load) {
    while (pwm_loading($pwm_module)) {
      sleep(0.010);                    # Wait for "LOAD" to complete
      if ((time() - $t_start) >= 1) {
        print_error("Timed out waiting for PWM load!");
        return;
      }
    }
  }
}

# Write an IO pin state or PWM duty cycle.
#    :param value: Either True/False for OUT, or a number between 0 and PWM period for PWM.
sub output {
  my ($pin, $value, $load, $wait_for_load) = @_;
  $load = 1 if not defined $load;
  $wait_for_load = 1 if not defined $wait_for_load;

  my $io_pin = $pins[$pin];
  #print_hash_params($io_pin);

  if ($io_pin->{mode} == $PIN_MODE_PWM) {
    #print_error("Outputting PWM $value to pin: $pin");
    my $pwml = $regs_pwml[$io_pin->{pwm_ch}];
    my $pwmh = $regs_pwmh[$io_pin->{pwm_ch}];
    write_i2c_byte($pwml, $value);
    write_i2c_byte($pwmh, $value >> 8);
    if ($load) {
      pwm_load($io_pin->{pwm_module}, $wait_for_load);
    }
  } else {
    if ($value == 0) {
      #print_error("Outputting LOW to pin: $pin (or HIGH if inverted)");
      change_bit($regs_p[$io_pin->{port}], $io_pin->{pin}, $io_pin->{inv_output});
    } else {
      if ($value == 1) {
        #print_error("Outputting HIGH to pin: $pin (or LOW if inverted)");
        change_bit($regs_p[$io_pin->{port}], $io_pin->{pin}, not $io_pin->{inv_output});
      }
    }
  }
}

sub reset_knob {
  my $t_start = time();
  set_bits($REGS::REG_CTRL, $REGS::MASK_CTRL_RESET);
  # Wait for a register to read its initialised value
  #print_error("reg = " . read_i2c_byte($REGS::REG_USER_FLASH));
  while (read_i2c_byte($REGS::REG_USER_FLASH) != 0x78) {
    sleep(0.010);
    if (time() - $t_start >= 1) {
      print_error("Timed out waiting for Reset!");
      print_error("reg = " . read_i2c_byte($REGS::REG_USER_FLASH));
      return;
    }
  }
  #print_error("reg = " . read_i2c_byte($REGS::REG_USER_FLASH));
}

# Set the colour of the knob
sub set_knob_colour {
  my ($colour, $intensity) = @_;
  my $ref = $colours{$colour};
  if (not defined $ref) {
    print_error("Illegal colour value $colour");
    return;
  }
  my ($r, $g, $b) = @$ref;
  #print("set colour $r/$g/$b\n");
  output($LED_RED, int($r * $intensity/100));
  output($LED_GREEN, int($g * $intensity/100));
  output($LED_BLUE, int($b * $intensity/100));
}

sub set_knob_hue {
  my $vol = shift;
  my $h = 280 * $vol / 100 + 80;
  my $s = 1;
  my $v = 1;
  my $hsv = Convert::Color->new("hsv:$h,$s,$v");
  my ($r, $g, $b) = $hsv->rgb;
  print_error("new knob colours: $r / $g / $b");
  output($LED_RED, int($r * 255));
  output($LED_GREEN, int($g * 255));
  output($LED_BLUE, int($b * 255));
}

# Clear the rotary encoder count value on a channel to 0."""
sub clear_rotary_encoder {
  my $channel = shift;
  if (($channel < 1) or ($channel > 4)) {
    print_error("Channel should be in range 1-4.");
    return;
  }
  $channel -= 1;

  # Reset internal encoder count to zero
  my @regs = ($REGS::REG_ENC_1_COUNT, $REGS::REG_ENC_2_COUNT, $REGS::REG_ENC_3_COUNT, $REGS::REG_ENC_4_COUNT);
  my $reg = $regs[$channel];
  write_i2c_byte($reg, 0);
  $encoder_last[$channel] = 0;
  $encoder_offset[$channel] = 0;
}

sub setup_rotary_encoder {
  my ($channel, $pin_a, $pin_b, $pin_c, $count_microsteps) = @_;
  $count_microsteps = 0 if not defined $count_microsteps;
  $channel -= 1;

  my $pin_ref;
  $pin_ref = $pins[$pin_a];
  my $enc_channel_a = $$pin_ref{enc_ch};
  $pin_ref = $pins[$pin_b];
  my $enc_channel_b = $$pin_ref{enc_ch};

  set_mode($pin_a, $PIN_MODE_PU, 1);
  set_mode($pin_b, $PIN_MODE_PU, 1);
  set_mode($pin_c, $PIN_MODE_OD);
  output($pin_c, 0);
  my @cfg = ($REGS::REG_ENC_1_CFG, $REGS::REG_ENC_2_CFG, $REGS::REG_ENC_3_CFG, $REGS::REG_ENC_4_CFG);
  write_i2c_byte($cfg[$channel], $enc_channel_a | ($enc_channel_b << 4));
  change_bit($REGS::REG_ENC_EN, $channel * 2 + 1, $count_microsteps);
  set_bit($REGS::REG_ENC_EN, $channel * 2);
  # Reset internal encoder count to zero
  clear_rotary_encoder($channel + 1);
}

# Read the step count from a rotary encoder."""
sub read_rotary_encoder {
  my $channel = shift;
  $channel = 1 if not defined $channel;
  if (($channel < 1) or ($channel > 4)) {
    print_error("Channel should be in range 1-4.");
    return;
  }
  $channel -= 1;
  my $last = $encoder_last[$channel];
  my $reg = ($REGS::REG_ENC_1_COUNT, $REGS::REG_ENC_2_COUNT, $REGS::REG_ENC_3_COUNT, $REGS::REG_ENC_4_COUNT)[$channel];
  my $value = read_i2c_byte($reg);

  if ($value & 0b10000000) {
    $value -= 256;
  }

  if (($last > 64) and ($value < -64)) {
    $encoder_offset[$channel] += 256;
  }
  if (($last < -64) and ($value > 64)) {
    $encoder_offset[$channel] -= 256;
  }

  $encoder_last[$channel] = $value;

  my $ret = $encoder_offset[$channel] + $value;
  #print("Read rotary encoder value = $ret\n");
  return $ret;
}

# Set the PWM period.
# The period is the point at which the PWM counter is reset to zero.
# The PWM clock runs at FSYS with a divider of 1/1.
# Also specifies the maximum value that can be set in the PWM duty cycle.
sub set_pwm_period {
  my ($value, $pwm_module, $load, $wait_for_load) = @_;
  $pwm_module = 0 if not defined $pwm_module;
  $load = 1 if not defined $load;
  $wait_for_load = 1 if not defined $wait_for_load;
  #print_error("set pwm period $value for $pwm_module");
  my $pwmpl = $REGS::REG_PWMPL;
  my $pwmph = $REGS::REG_PWMPH;
  write_i2c_byte($pwmpl, $value);
  write_i2c_byte($pwmph, $value >> 8);
  if ($load) {
    pwm_load($pwm_module, $wait_for_load);
  }
}

# Set PWM settings.
# PWM is driven by the 24MHz FSYS clock by default.
# :param divider: Clock divider, one of 1, 2, 4, 8, 16, 32, 64 or 128
sub set_pwm_control {
  my ($divider, $pwm_module) = @_;
  $pwm_module = 0 if not defined $pwm_module;
  my @divs;
  $divs[1] = 0b000;
  $divs[2] = 0b001;
  $divs[4] = 0b010;
  $divs[8] = 0b011;
  $divs[16] = 0b100;
  $divs[32] = 0b101;
  $divs[64] = 0b110;
  $divs[128] = 0b111;
  my $pwmdiv2 = $divs[$divider];
  if (not defined $pwmdiv2) {
    print_error("A clock divider of $divider");
    return;
  }
  write_i2c_byte($REGS::REG_PWMCON1, $pwmdiv2);
}

sub init_knob {
  $volume_device = Device::I2C->new('/dev/i2c-1', O_RDWR);
  reset_knob();
  @pins = ({},                                                                                                                                                                                    # Pin |  ADC   |  PWM   |  ENC  |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM],                      port => 1, pin => 5, enc_ch => 1,  inv_output => 0, reg_iopwm => 1, bit_iopwm => 5, pwm_module => 0, pwm_ch => 5},               # 1   |        | [CH 5] | CH 1  |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM],                      port => 1, pin => 0, enc_ch => 2,  inv_output => 0, reg_iopwm => 0, bit_iopwm => 2, pwm_module => 0, pwm_ch => 2},               # 2   |        | [CH 2] | CH 2  |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM],                      port => 1, pin => 2, enc_ch => 3,  inv_output => 0, reg_iopwm => 0, bit_iopwm => 0, pwm_module => 0, pwm_ch => 0},               # 3   |        | [CH 0] | CH 3  |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM],                      port => 1, pin => 4, enc_ch => 4,  inv_output => 0, reg_iopwm => 1, bit_iopwm => 1, pwm_module => 0, pwm_ch => 1},               # 4   |        | [CH 1] | CH 4  |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM],                      port => 0, pin => 0, enc_ch => 5,  inv_output => 0, reg_iopwm => 0, bit_iopwm => 3, pwm_module => 0, pwm_ch => 3},               # 5   |        | [CH 3] | CH 5  |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM],                      port => 0, pin => 1, enc_ch => 6,  inv_output => 0, reg_iopwm => 0, bit_iopwm => 4, pwm_module => 0, pwm_ch => 4},               # 6   |        | [CH 4] | CH 6  |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM, $PIN_MODE_ADC],       port => 1, pin => 1, enc_ch => 7,  inv_output => 0, reg_iopwm => 0, bit_iopwm => 1, pwm_module => 0, pwm_ch => 1, adc_ch => 7},  # 7   | [CH 7] |  CH 1  | CH 7  |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM, $PIN_MODE_ADC],       port => 0, pin => 3, enc_ch => 8,  inv_output => 0, reg_iopwm => 0, bit_iopwm => 5, pwm_module => 0, pwm_ch => 5, adc_ch => 6},  # 8   | [CH 6] |  CH 5  | CH 8  |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM, $PIN_MODE_ADC],       port => 0, pin => 4, enc_ch => 9,  inv_output => 0, reg_iopwm => 1, bit_iopwm => 3, pwm_module => 0, pwm_ch => 3, adc_ch => 5},  # 9   | [CH 5] |  CH 3  | CH 9  |
    {type => [$PIN_MODE_IO, $PIN_MODE_ADC],                      port => 3, pin => 0, enc_ch => 10, inv_output => 0,                                                               adc_ch => 1},  # 10  | [CH 1] |        | CH 10 |
    {type => [$PIN_MODE_IO, $PIN_MODE_ADC],                      port => 0, pin => 6, enc_ch => 11, inv_output => 0,                                                               adc_ch => 3},  # 11  | [CH 3] |        | CH 11 |
    {type => [$PIN_MODE_IO, $PIN_MODE_PWM, $PIN_MODE_ADC],       port => 0, pin => 5, enc_ch => 12, inv_output => 0, reg_iopwm => 1, bit_iopwm => 2, pwm_module => 0, pwm_ch => 2, adc_ch => 4},  # 12  | [CH 4] |  CH 2  | CH 12 |
    {type => [$PIN_MODE_IO, $PIN_MODE_ADC],                      port => 0, pin => 7, enc_ch => 13, inv_output => 0,                                                               adc_ch => 2},  # 13  | [CH 2] |        | CH 13 |
    {type => [$PIN_MODE_IO, $PIN_MODE_ADC],                      port => 1, pin => 7, enc_ch => 14, inv_output => 0,                                                               adc_ch => 0},  # 14  | [CH 0] |        | CH 14 |
  );
  @regs_pwml = ($REGS::REG_PWM0L, $REGS::REG_PWM1L, $REGS::REG_PWM2L, $REGS::REG_PWM3L, $REGS::REG_PWM4L, $REGS::REG_PWM5L);
  @regs_pwmh = ($REGS::REG_PWM0H, $REGS::REG_PWM1H, $REGS::REG_PWM2H, $REGS::REG_PWM3H, $REGS::REG_PWM4H, $REGS::REG_PWM5H);
  @regs_piocon = ($REGS::REG_PIOCON0, $REGS::REG_PIOCON1);
  @regs_m1 = ($REGS::REG_P0M1, $REGS::REG_P1M1, -1, $REGS::REG_P3M1);
  @regs_m2 = ($REGS::REG_P0M2, $REGS::REG_P1M2, -1, $REGS::REG_P3M2);
  @regs_p = ($REGS::REG_P0, $REGS::REG_P1, $REGS::REG_P2, $REGS::REG_P3);
  @regs_ps = ($REGS::REG_P0S, $REGS::REG_P1S, $REGS::REG_P2S, $REGS::REG_P3S);

  # Set up the interrupt pin on the Pi, and enable the chip's output (???)
  set_bit($REGS::REG_INT, $REGS::BIT_INT_OUT_EN);
  change_bit($REGS::REG_INT, $REGS::BIT_INT_PIN_SWAP, 1);

  setup_rotary_encoder(1, $KNOB_A, $KNOB_B, $KNOB_C);
  set_pwm_period(510);
  set_pwm_control(2, undef);
  #print("set mode for red\n");
  set_mode($LED_RED, $PIN_MODE_PWM, undef, 1);
  #print("set mode for green\n");
  set_mode($LED_GREEN, $PIN_MODE_PWM, undef, 1);
  #print("set mode for blue\n");
  set_mode($LED_BLUE, $PIN_MODE_PWM, undef, 1);
  $knob = read_rotary_encoder(1);
}


1;
