package Data::Structure::Util;

use strict;
use warnings::register;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

$VERSION = '0.08';
BEGIN {
  if ($] < 5.008) {
    @EXPORT_OK = qw(unbless get_blessed get_refs has_circular_ref circular_off signature);
  }
  else {
    @EXPORT_OK = qw(has_utf8 utf8_off utf8_on unbless get_blessed get_refs has_circular_ref circular_off signature);
  }
}

bootstrap Data::Structure::Util $VERSION;

sub has_utf8 {
  has_utf8_xs($_[0]) ? $_[0] : undef;
}

sub utf8_off {
  utf8_off_xs($_[0]) ? $_[0] : undef;
}

sub utf8_on {
  utf8_on_xs($_[0]) ? $_[0] : undef;
}

sub unbless {
  unbless_xs($_[0]);
}

sub get_blessed {
  $_[0] or return [];
  get_blessed_xs($_[0]);
}

sub get_refs {
  $_[0] or return [];
  get_refs_xs($_[0]);
}

sub has_circular_ref {
  $_[0] or return $_[0];
  has_circular_ref_xs($_[0]);
}

sub circular_off {
  $_[0] or return $_[0];
  circular_off_xs($_[0]);
}

sub signature {
  @_ ? md5_hex(Dumper([ $_[0], signature_xs($_[0]) ]))
     : '0' x 32;
}

1;

__END__


=head1 NAME

Data::Structure::Util - Change nature of data within a structure

=head1 SYNOPSIS

  use Data::Structure::Util qw(has_utf8 utf8_off utf8_on unbless get_blessed has_circular_ref);
  
  $data = {
            key1 => 'hello',
            key2 => bless({}, 'Foo'),
          };
  $data->{key3} = \$data;

  utf8_off($data) if has_utf8($data);

  $objs = get_blessed($data);
  unbless($data) if @$objs;

  die "Found a circular reference!" if has_circular_ref($data);

=head1 DESCRIPTION

C<Data::Structure::Util> is a toolbox to manipulate data inside a data structure.
It can parse an entire tree and perform the operation requested on each appropriate element.
It can transform to utf8 any string within a data structure. I can attempts to
transform any utf8 string back to default encoding either.
It can remove the blessing on any reference. It can collect all the objects
or detect if there is a circular reference.

It is written in C for decent speed.

=head1 FUNCTIONS

=over 4

=item has_utf8($var)

Returns $var if there is an utf8 (as noted by perl) string anywhere within $var.
Returns undef if no utf8 string has been found.

=item utf8_off($var)

Attempts to decode from utf8 any string within $var. Returns $var.
If successful, the resulting string will not not be flagged as utf8.

=item utf8_on($var)

Encode to utf8 any string within $var. Returns $var.
The resulting string will flagged as utf8.

=item unbless($ref)

Remove the blessing from any object found wihtin the date structure referenced by $ref

=item get_blessed($ref)

Returns an array ref of all objects within the data structure. The data structure is parsed deep first,
so the top most objects should be the last elements of the array.

=item get_refs($ref)

Decomposes the data structure by returning an array ref of all references within. The data structure is parsed deep first,
so the top most references should be the last elements of the array.

=item has_circular_ref($ref)

If a circular reference is detected, it returns the reference to an element composing the circuit.
Returns false if no circular reference is detected.
If the version of perl enables weaken references, these are skipped and are not reported as part of a circular reference.

Example:

  if ($circular_ref = has_circular_ref($ref)) {
    warn "Got a circular reference " . Dumper($circular_ref) .
         "You can use 'weaken' from Scalar::Util module to break it";
  }

=item circular_off($ref)

Weaken any reference part of a circular reference in an attempt to break it.
Returns the number of references newly weaken.

=item signature($ref)

Returns a md5 of the $ref. Any change in the structure should change the signature.
It examines the structure, addresses, value types and flags to generate the signature.

Example:

  $ref1 = { key1 => [] };
  $ref2 = $ref1;
  $ref2->{key1} = [];

signature($ref1) and signature($ref2) will be different, even if they look the same using Data::Dumper;

=back

=head1 SEE ALSO

C<Scalar::Util>, C<Devel::Leak>, C<Devel::LeakTrace>

See the excellent article http://www.perl.com/pub/a/2002/08/07/proxyobject.html from Matt Sergeant for more info on circular references

=head1 BUGS

  Using perl 5.8.0, there is a pathological case where circular_off will fail, I don't know why yet:
  my $obj8 = [];
  $obj8->[0] = \$obj8;
  circular_off($obj8); # Will throw an error

  signature() is sensitive to the hash randomisation algorithm
  
=head1 THANKS TO

James Duncan and Arthur Bergman who provided me with help and a name for this module.
Richard Clamp has provided invaluable help to debug this module.

=head1 AUTHOR

Pierre Denis <pdenis@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut
