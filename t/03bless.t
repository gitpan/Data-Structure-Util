#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Data::Structure::Util qw(unbless get_blessed has_circular_ref); 
use Data::Dumper;


use Test::Simple tests => 11;

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


ok( my $objects = get_blessed($obj), "Got objects");
ok( $objects->[1] == $obj->{key3}->{key32} || $objects->[1] == $obj->{key1}->[3] || $objects->[1] == $obj->{key5} , "Got object 1");
ok( $objects->[2] == $obj->{key1}->[3] || $objects->[2] == $obj->{key3}->{key32} || $objects->[2] == $obj->{key5} , "Got object 2");
ok( $objects->[3] == $obj, "Got top object");
ok( ! @{get_blessed(undef)}, "undef");
ok( ! @{get_blessed('hello')}, "hello");
ok( ! @{get_blessed()}, "undef");


ok( $obj == unbless($obj), "Have unblessed obj");
ok( ref $obj eq 'HASH', "Not blessed anymore");
ok( ref $obj->{key1}->[3] eq 'HASH', "Not blessed anymore");

