#!/usr/bin/perl -T

use strict;
use warnings;
use Term::ANSIColor;
use Term::Size;
use Math::Prime::Util qw(lcm);

my %opt = getoptions();

my $lcm = lcm(map { $$_[0] } @{$opt{subword}});
my $colorcount = ($lcm > scalar @{$opt{clrcode}}) ? scalar @{$opt{clrcode}} : $lcm;

print "\n"; my $col = 0;
for my $n ($opt{from} .. $opt{to}) {
  my $say = "";
  for my $sw (@{$opt{subword}}) {
    my ($divisor, $word) = @$sw;
    if (not ($n % $divisor)) {
      $say .= $word;
    }
  }
  dosay(($say || donumber($n)),
        $opt{clrcode}[$n % $colorcount],
        (($n > $opt{from}) ? 0 : 1));
}
print "\n";

exit 0; # Subroutines follow.

sub dosay {
  my ($text, $clr, $nosep) = @_;
  $clr ||= "";
  my $sep = $nosep ? "" : $opt{sep};
  # Do we need to wrap?
  if ($col + length($sep) + length($text) >= $opt{termwidth}) {
    print "\n" . $clr . $text . color("reset");
    $col = length($text);
  } else {
    print $sep . $clr . $text . color("reset");
    $col += length($sep) + length($text);
  }
}

sub donumber {
  my ($n, $thoulvl) = @_;
  return $n if not $opt{spell};
  $thoulvl   ||= 0;
  my @one      = qw(Zero One Two Three Four Five Six Seven Eight Nine);
  my @ten      = ("", qw(Ten Twenty Thirty Fourty Fifty Sixty Seventy Eighty Ninety));
  my @thousand = (qw(Thousand Million Billion Trillion));
  my %special  = ( 11 => "Eleven", 12 => "Twelve", 13 => "Thirteen", 15 => "Fifteen", map { $_ => $one[$_ - 10] . "teen" } (14, 16 .. 19));
  if ($n > 1000) {
    my $smalln = donumber($n % 1000, 0);
    return donumber(int($n / 1000), $thoulvl + 1) . " " . ($thousand[$thoulvl] || "Xillion")
      . ($smalln ? " " : "") . $smalln;
  }
  if ($n > 100) {
    my $smalln = donumber($n % 100, 0);
    return donumber(int($n / 100), 0) . " Hundred" . ($smalln ? ($opt{American} ? " " : " and ") : "") . $smalln;
  }
  if ($special{$n}) { return $special{$n} }
  if ($n > 10) {
    my $smalln = donumber($n % 10, 0);
    return $ten[int($n / 10)] . ($smalln ? ($opt{hyphens} ? "-" : " ") : "") . $smalln;
  }
  return $one[$n] || $n;
}

sub getoptions {
  my @basecolorname = qw(black red green yellow blue magenta cyan white);

  my %default = (
                 subword => [ [ 3 => "Fizz", ], [ 5 => "Buzz" ], ],
                 clrcode => [ map { color($_)
                                  } (@basecolorname, (map { "bright_" . $_ } @basecolorname))],
                 from    => 1,
                 to      => 100,
                 sep     => " ",
                 hyphens => 0,
                 spell   => 1,
                 wrap    => 1,
                );
  ($default{termwidth}, $default{termheight}) =  Term::Size::chars *STDOUT{IO};
  $default{termwidth} ||= 60; # Sane default if we can't find the actual width.

  my %option;
  while (scalar @ARGV) {
    my $arg = shift @ARGV;
    if ((defined $default{$arg}) and not ref $default{arg}) {
      # Scalar option, just set it.
      $option{$arg} = shift @ARGV;
    } elsif ($arg eq "use") {
      $option{shift @ARGV} = 1;
    } elsif ($arg eq "no") {
      $option{shift @ARGV} = 0;
    }
    # TODO: handle other option syntax, and allow setting the subwords, colors, etc.
  }

  # Use the defaults for any option not specified:
  for my $k (keys %default) {
    $option{$k} = $default{$k} if not defined $option{$k};
  }
  return %option;
}


