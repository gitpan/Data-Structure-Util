#!perl -w

use strict;

# this file checks against a bug discovered by Mark Fowler
# essentially magic values arn't being downgraded

BEGIN {
  if ($] < 5.008) {
    my $reason = "This version of perl ($]) doesn't have proper utf8 support, 5.8.0 or higher is needed";
    eval qq{ use Test::More skip_all => "$reason" };
    exit;
  }
}

use Encode ();
use Data::Structure::Util ();
use Test::More tests => 6;
use Devel::Peek;

{
 my $smile = "\x{263a}";
 my $len = length($smile);
 Encode::_utf8_off($smile);
 isnt($len,length($smile),"encode length")
   or Dump($smile);
}

{
 my $smile = "\x{263a}";
 my $len = length($smile);
 Data::Structure::Util::_utf8_off($smile);
 isnt($len,length($smile),"data structure util length")
  or Dump($smile);
}

{
  my $smile = "\x{263a}";
  my $foo = \$smile;
  my $len = length($smile);
  Data::Structure::Util::_utf8_off($foo);
  isnt($len,length($smile),"data structure util length with ref")
   or Dump($smile);
}

{
 my $smile = "\x{263a}";
 my $len = length($smile);
 eval {
   Data::Structure::Util::utf8_off($smile);
 };
 like($@, qr/Wide character/, "correct error for wideness")
  or Dump($smile);
}

{
 my $smile = "foo\x{263a}";
 my $len = length($smile);
 chop $smile;
 Data::Structure::Util::utf8_off($smile);
 use bytes;
 is(length $smile,"3", "utf8_off");
 is($smile,"foo", "utf8_off pt2");
}