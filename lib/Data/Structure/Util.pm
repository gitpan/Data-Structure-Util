package Data::Structure::Util;

use strict;
use warnings::register;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

$VERSION = '0.03';
@EXPORT = qw( );
BEGIN {
  if ($] < 5.008) {
    @EXPORT_OK = qw(unbless get_blessed has_circular_ref);
  }
  else {
    @EXPORT_OK = qw(has_utf8 utf8_off utf8_on unbless get_blessed has_circular_ref);
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

sub has_circular_ref {
  $_[0] or return 0;
  has_circular_ref_xs($_[0]);
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
It can transform to utf8 any string within a data structure. I can attempts to
transform any utf8 string back to default encoding either.
It can remove the blessing on any reference. It can collect all the objects
or detect if there is a circular reference.

It is written in C for decent speed.

=head1 FUNCTIONS

=over 4

=item has_utf8($var)

Returns $var if there is a utf8 (as noted by perl) string anywhere within $var.
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

=item has_circular_ref($ref)

If a circular reference is detected, it returns the reference to an element composing the circuit.
Returns false if no circular reference is detected.
If the version of perl enables weaken references, these are skipped and are not reported as part of a circular reference.

Example:

  if ($circular_ref = has_circular_ref($ref)) {
    warn "Got a circular reference " . Dumper($circular_ref) . "You can use 'weaken' from Scalar::Util module to break it";
  }

=back

=head1 SEE ALSO

C<Scalar::Util>, C<Devel::Leak>, C<Devel::LeakTrace>

See the excellent article http://www.perl.com/pub/a/2002/08/07/proxyobject.html from Matt Sergeant for more info on circular references

=head1 THANKS TO

James Duncan and Arthur Bergman who provided me with help and a name for this module

=head1 AUTHOR

Pierre Denis <pdenis@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut
