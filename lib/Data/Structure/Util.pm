package Data::Structure::Util;

use strict;
use warnings::register;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Carp;
require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

$VERSION = '0.02';
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
  has_utf8_xs(@_) ? $_[0] : undef;
}

sub utf8_off {
  utf8_off_xs(@_) ? $_[0] : undef;
}

sub utf8_on {
  utf8_on_xs(@_) ? $_[0] : undef;
}

sub unbless {
  unbless_xs(@_);
}

sub get_blessed {
  $_[0] or return [];
  get_blessed_xs($_[0]);
}

sub has_circular_ref {
  $_[0] or return 0;
  has_circular_ref_xs(@_);
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

=item has_utf8($ref)

Returns true if there is a utf8 (as noted by perl) string within the data structure referenced by $ref

=item utf8_off($ref)

Attempts to decode from utf8 any string within the data structure referenced by $ref

=item utf8_on($ref)

Encode to utf8 any string within the data structure referenced by $ref

=item unbless($ref)

Remove the blessing from any object found wihtin the date structure referenced by $ref

=item get_blessed($ref)

Returns an array ref of all objects within the data structure. The data structure is parsed deep first,
so the top most objects should be the last elements of the array.

=item has_circular_ref($ref)

If a circular reference is detected, it returns the reference to an element composing the circuit.
Returns false if no circular reference is detected. Example:

  if ($circular_ref = has_circular_ref($ref)) {
    warn "Got a circular reference, you can use 'weaken' from Scalar::Util module to break it";
  }

=back

=head1 SEE ALSO

C<Scalar::Util>, C<Devel::Leak>, C<Devel::LeakTrace>

=head1 THANKS TO

James Duncan and Arthur Bergman who provided me with help and a name for this module

=head1 AUTHOR

Pierre Denis <pdenis@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut
