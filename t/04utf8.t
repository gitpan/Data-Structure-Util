#!/usr/bin/perl

use lib qw(. blib lib);
use Data::Structure::Util qw(has_utf8 utf8_off utf8_on unbless get_blessed has_circular_ref); 
use Data::Dumper;
use Clone qw(clone);

use Test::Simple tests => 13;

ok(1,"we loaded fine...");


my $string = '';
foreach my $v ( 32 .. 126, 195 .. 255 ) {
  $string .= chr($v);
}
        
my $hash = {
              key1 => $string . "\n",
           };


my $hash2 = test_utf8($hash);
if ($hash2) {
  ok(1, "Got a utf8 string");
}
else {
  $hash2 = clone($hash);
  ok( utf8_on($hash), "Have encoded utf8");
}
ok( ! has_utf8($hash), "Has not utf8");
ok( has_utf8($hash2), "Has utf8");

ok( $hash2->{key1} eq $hash->{key1}, "Same string");
ok( ! compare($hash2->{key1}, $hash->{key1}), "Different encoding");
ok( utf8_off($hash2), "Have decoded utf8");
ok( ! has_utf8($hash2), "Has not utf8");
ok( $hash2->{key1} eq $hash->{key1}, "Same string");
ok( compare($hash2->{key1}, $hash->{key1}), "Same encoding");

ok( utf8_on($hash), "Have encoded utf8");
ok( $hash2->{key1} eq $hash->{key1}, "Same string");
ok( ! compare($hash2->{key1}, $hash->{key1}), "Different encoding");


sub compare {
  my $str1 = shift;
  my $str2 = shift;
  my $i = 0;
  my @chars2 = unpack 'C*', $str2;
  foreach my $char1 (unpack 'C*', $str1) {
    return if (ord($char1) != ord($chars2[$i++]));
  }
  1;
}


sub test_utf8 {
  my $hash = shift;
  
  eval q{ use Encode };
  if ($@) {
    warn "Encode not installed - $@ - will try XML::Simple\n";
    eval q{ use XML::Simple qw(XMLin XMLout) };
    if ($@) {
      warn "XML::Simple not installed - $@\n";
      return;
    }
    my $xml = XMLout($hash, keyattr => [], noattr => 1, suppressempty => undef, xmldecl => '<?xml version="1.0" encoding="ISO-8859-1"?>');
    return XMLin($xml, keyattr => [], suppressempty => undef);
  }
  my $hash2 = clone($hash) or die "Could not clone";
  my $utf8 = decode("iso-8859-1", $hash->{key1});
  $hash2->{key1} = $utf8;
  $hash2;
}
