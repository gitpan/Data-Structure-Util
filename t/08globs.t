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
use Test::More tests => 1;
use Devel::Peek;


TODO: {

  local $TODO = "Make work with globs";

  my $smile = "\x{263a}";
  *foo = \$smile;
  my $len = length($smile);
  Data::Structure::Util::_utf8_off(\*foo);
  isnt($len,length($smile),"data structure util length with ref");
}
