#!/usr/bin/perl

use blib;
use Data::Structure::Util qw(has_utf8 utf8_off utf8_on unbless get_blessed has_circular_ref); 
use Data::Dumper;

use Test::Simple tests => 13;

ok(1,"we loaded fine...");


my $obj = bless {
                  key1 => [1, 2, 3, bless {} => 'Tagada'],
                  key2 => undef,
                  key3 => {
                            key31 => {},
                            key32 => bless { bla => [] } => 'Tagada',
                          },
                  key5 => bless [] => 'Ponie',
                } => 'Scoobidoo';
$obj->{key4} = \$obj;
$obj->{key3}->{key33} = $obj->{key3}->{key31};

my $thing = { var1 => {} };
$thing->{var2} = [ $thing->{var1}->{hello } ];
$thing->{var1}->{hello} = $thing->{var2};

my $obj2 = { key1 => [ sub { [] } ] };
$obj2->{key2} = $obj2->{key1};

my $obj3;
$obj3 = \$obj3;

my $obj4 = { key1 => $obj3 };

our @V1 = (1, 2, sub {} );
my $obj5 = {
             key1 => undef,
             key2 => sub {},
             key3 => \@V1,
             key4 => $obj2,
             key5 => {
                       key51 => sub {},
                       key52 => \*STDERR,
                       key53 => [0, \"hello"],
                     },
           };
$obj5->{key5}->{key53}->[2] = $obj5->{key5};
$obj5->{key5}->{key54} = $obj5->{key5}->{key53}->[2];
$obj5->{key6} = $obj5->{key5}->{key53}->[2];
$obj5->{key5}->{key55} = $obj5->{key5}->{key53}->[2];

my $obj6 = { key1 => undef };
my $obj = $obj6;
my $V2 = [1, undef, \5, sub {} ];
foreach (1 .. 50) {
  $obj->{key2} = {};
  $obj->{key1} = $V2;
  $obj = $obj->{key2};
}
$obj->{key3} = \$obj6;

ok(! has_circular_ref($thing), "Not a circular ref");

my $ref = has_circular_ref($obj);
ok($ref, "Got a circular reference");
ok($ref == $obj, "reference is correct");

ok(! has_circular_ref($obj2), "No circular reference");
ok(has_circular_ref($obj3), "Got a circular reference");
ok(has_circular_ref($obj4), "Got a circular reference");
ok(has_circular_ref($obj5), "Got a circular reference");
ok(has_circular_ref($obj6), "Got a circular reference");
ok($obj6 == has_circular_ref($obj6), "Match reference");


ok(! has_circular_ref(), "No circular reference");
ok(! has_circular_ref( [] ), "No circular reference");
ok(has_circular_ref( [ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\$ref ] ), "Has circular reference");
