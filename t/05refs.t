#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Data::Structure::Util qw(has_utf8 utf8_off utf8_on unbless get_blessed get_refs has_circular_ref);
use Data::Dumper;


use Test::Simple tests => 16;

ok(1,"we loaded fine...");


my $obj = bless {
                  key1 => [1, 2, 3, bless {} => 'Tagada'],
                  key2 => undef,
                  key3 => {
                            key31 => {},
                            key32 => bless { bla => [undef] } => 'Tagada',
                          },
                  key5 => bless [] => 'Ponie',
                } => 'Scoobidoo';
$obj->{key4} = \$obj;
$obj->{key3}->{key33} = $obj->{key3}->{key31};


ok( my $objects = get_refs($obj), "Got references");
ok( @$objects == 9, "got all");
my $found;
foreach my $ref (@$objects) {
  if ($ref == $obj) { $found++; ok(1) };
  if ($ref == $obj->{key1}) { $found++; ok(1) };
  if ($ref == $obj->{key1}->[3]) { $found++; ok(1) };
  if ($ref == $obj->{key3}) { $found++; ok(1) };
  if ($ref == $obj->{key3}->{key31}) { $found++; ok(1) };
  if ($ref == $obj->{key3}->{key32}) { $found++; ok(1) };
  if ($ref == $obj->{key3}->{key32}->{bla}) { $found++; ok(1) };
  if ($ref == $obj->{key5}) { $found++; ok(1) };
  if ($ref == \$obj) { $found++; ok(1) };
}
ok( $found == @$objects, "Found " . scalar(@$objects) );

ok( ! @{get_refs(undef)}, "undef");
ok( ! @{get_refs('hello')}, "hello");
ok( ! @{get_refs()}, "undef");

