#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Data::Dumper;

our $PERL_HAS_UTF8;
BEGIN {
  if ($] < 5.008) {
    eval q{ use Data::Structure::Util qw(signature) };
    die $@ if $@;
    $PERL_HAS_UTF8 = 0;
  }
  else {
    eval q{ use Data::Structure::Util qw(has_utf8 utf8_off utf8_on signature) };
    die $@ if $@;
    $PERL_HAS_UTF8 = 1;
  }
}

use Test::More tests => 15;

ok(1,"we loaded fine...");


my $obj = {};
ok( signature($obj) ne signature({}), "Signature 1");

my $obj2 = [];
ok( signature($obj2) ne signature([]), "Signature 2");

my $obj3 = bless { key1 => 1 };
ok( my $sig3 = signature($obj3));
ok( $sig3 ne signature(bless { key1 => 1 }), "Signature 3");
$obj3->{key1} = 1;
ok( $sig3 eq signature($obj3), "Signature 3");


my $obj4 = bless { key1 => $obj3, key2 => $obj2, key3 => $obj, key4 => undef };
ok( my $sig4 = signature($obj4));
ok( $sig4 ne signature(bless { key1 => $obj3, key2 => $obj2, key3 => $obj, key4 => undef }), "Signature 3");

$obj4->{key1} = bless{ key1 => 1 };
ok( signature($obj4) ne $sig4, "Signature 4");


ok( signature(), "none");
ok( signature() eq signature(), "empty list");
ok( my $sigundef = signature(undef), "none");
ok( $sigundef ne signature(undef), "none");


# BELOW THIS LINE REQUIRES PERL 5.8.0 OR GREATER
SKIP: {
  unless ($PERL_HAS_UTF8) {
    my $reason = "This version of perl ($]) doesn't have proper utf8 support, 5.8.0 or higher is needed";
    skip($reason, 2);
    exit;
  }
  my %hash = ( key1 => "Hello" );
  utf8_off(\%hash);
  my $sig5 = signature(\%hash);
  ok( $sig5 eq signature(\%hash), "signature 5");
  utf8_on(\%hash);
  ok( $sig5 ne signature(\%hash), "signature 5");
}

