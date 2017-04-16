#!/usr/bin/perl -T

use strict;
use warnings;
use Term::ANSIColor;
use Term::Size;
use Math::Prime::Util qw(lcm);

my $defaultlang = "English";
my %opt;

my %langsynonym = ( "en"     => "English",
                    "en-us"  => "English",
                    "jp"     => "Japanese",
                    "日本語" => "Japanese",
                  );
my %langsupport =
  (
   Japanese =>
   +{ nolangsupport =>
      sub { my ($lang) = @_;
            return "${lang}の言語サポートはありません。もしわけありません。", },
      donumber =>
      sub {
        my ($n) = @_;
        if ($n == 0) { return "零"; }
        my @ichi  = ("", "一", "二", "三", "四", "五", "六", "七", "八", "九");
        my @juu   = ("", "十", map { $ichi[$_] . "十" } 2 .. 9);
        my @hyaku = ("", "百", map { $ichi[$_] . "百" } 2 .. 9);
        my @sen   = ("", "千", map { $ichi[$_] . "千" } 2 .. 9);
        my $prefix = "";
        if ($n > 10000) {
          $prefix = donumber(int($n / 10000)) . "万";
          $n = $n % 10000;
        }
        return ((join "", grep { $_ } ($prefix,
                                       $sen[int($n / 1000)],
                                       $hyaku[int(($n % 1000) / 100)],
                                       $juu[int(($n % 100) / 10)],
                                       $ichi[$n % 10])) || "");
      },
    },
   English =>
   +{ nolangsupport =>
      sub { my ($lang) = @_;
            return "No language support for $lang, resorting to English.  Sorry.\n"  },
      donumber =>
      sub {
        my ($n, $thoulvl) = @_;
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
      },
    },
  );

%opt = getoptions();
checklangsupport();

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

sub checklangsupport {
  if (not $langsupport{$opt{lang}}) {
    if ($langsynonym{$opt{lang}}) {
      $opt{lang} = $langsynonym{$opt{lang}};
      checklangsupport();
    } else {
      if (not $langsupport{$defaultlang}) {
        die "No language support for default language ($defaultlang)"
      }
      warn $langsupport{$defaultlang}{nolangsupport}->($opt{lang});
      $opt{lang} = $defaultlang;
    }
  }
}

sub donumber {
  my (@arg) = @_;
  return join($opt{sep}, @arg) if not $opt{spell};
  return $langsupport{$opt{lang}}{donumber}->(@arg);
}

sub getoptions {
  my @basecolorname = qw(black red green yellow blue magenta cyan white);

  my %default = (
                 subword => [ [ 3 => "Fizz", ], [ 5 => "Buzz" ], ],
                 clrcode => [ map { color($_)
                                  } (@basecolorname, (map { "bright_" . $_ } @basecolorname))],
                 lang    => $defaultlang,
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


