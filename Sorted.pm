package Tie::Array::Sorted;
use base 'Tie::Array';
use 5.006;
use strict;
use warnings;
our $VERSION = '1.2';

=head1 NAME

Tie::Array::Sorted - An array which is kept sorted

=head1 SYNOPSIS

  use Tie::Array::Sorted;
  tie @a, "Tie::Array::Sorted", sub { $_[0] <=> $_[1] };
  push @a, 10, 4, 7, 3, 4;
  print "@a"; # "3 4 4 7 10"

=head1 DESCRIPTION

This presents an ordinary array, but is kept sorted. All pushes and
unshifts cause the elements in question to be inserted in the
appropriate location to maintain order.

Direct stores (C<$a[10] = "wibble">) effectively splice out the original
value and insert the new element. It's not clear why you'd want to use
direct stores like that, but this module does the right thing if you do.

If you don't like the ordinary lexical comparator, you can provide your
own; it should compare the two elements it is given. For instance, a
numeric comparator would look like this:

    tie @a, "Tie::Array::Sorted", sub { $_[0] <=> $_[1] }

Whereas to compare a list of files by their sizes, you'd so something
like:

    tie @a, "Tie::Array::Sorted", sub { -s $_[0] <=> -s $_[1] }

=head1 LAZY SORTING

You may find, after profiling your code, that you do far more stores
than fetches. In this case, doing a sorted insertion is inefficient, and
you only need to sort on retrieval. You can turn on lazy sorting by
tying to the C<Tie::Array::Sorted::Lazy> subclass, which does the
right thing. Naturally, it only re-sorts if data has been added since
the last sort.

    tie @a, "Tie::Array::Sorted::Lazy", sub { -s $_[0] <=> -s $_[1] };

=cut

sub TIEARRAY  { 
    my ($class, $comparator) = @_;
    bless {
        array => [],
        comp  => (defined $comparator ? $comparator : sub { $_[0] cmp $_[1] })
    }, $class;
}

sub STORE {
    my ($self, $index, $elem) = @_;
    splice @{$self->{array}}, $index, 0;
    $self->PUSH($elem);
}

sub PUSH { 
    my ($self, @elems) = @_;
    ELEM: for my $elem (@elems) {
        my ($lo, $hi) = (0, $#{$self->{array}});
        while ($hi >= $lo) {
            my $mid = int(($lo+$hi)/2);
            my $mid_val = $self->{array}[$mid];
            my $cmp = $self->{comp}($elem, $mid_val);
            if ($cmp == 0) {
                splice(@{$self->{array}}, $mid, 0, $elem);
                next ELEM;
            } elsif ($cmp > 0) { $lo = $mid + 1 }
            elsif ($cmp < 0) { $hi = $mid - 1 }
        }
        splice(@{$self->{array}}, $lo, 0, $elem);
    }
}

sub UNSHIFT { goto &PUSH }

sub FETCHSIZE { scalar @{$_[0]->{array}} }
sub STORESIZE { $#{$_[0]->{array}} = $_[1]-1 }
sub FETCH     { $_[0]->{array}->[$_[1]] }
sub CLEAR     { @{$_[0]->{array}} = () }
sub POP       { pop(@{$_[0]->{array}}) }
sub SHIFT     { shift(@{$_[0]->{array}}) }

sub EXISTS    { exists $_[0]->{array}->[$_[1]] }
sub DELETE    { delete $_[0]->{array}->[$_[1]] }

package Tie::Array::Sorted::Lazy;
use base 'Tie::Array::Sorted';
sub PUSH {
    my ($self, @elems) = @_;
    $self->{dirty} = 1;
    push @{$self->{array}}, @elems;
}
sub UNSHIFT {
    my ($self, @elems) = @_;
    $self->{dirty} = 1;
    push @{$self->{array}}, @elems;
}

sub fixup {
    my $self = shift;
    $self->{array} = [sort {$self->{comp}->($a,$b)} @{$self->{array}}];
    $self->{dirty} = 0;
}

sub FETCH { $_[0]->fixup if $_[0]->{dirty}; shift->SUPER::FETCH(@_); }
sub STORESIZE { $_[0]->fixup if $_[0]->{dirty}; shift->SUPER::STORESIZE(@_); }
sub POP { $_[0]->fixup if $_[0]->{dirty}; shift->SUPER::POP(@_); }
sub SHIFT { $_[0]->fixup if $_[0]->{dirty}; shift->SUPER::SHIFT(@_); }
sub EXIST { $_[0]->fixup if $_[0]->{dirty}; shift->SUPER::EXIST(@_); }
sub DELETE { $_[0]->fixup if $_[0]->{dirty}; shift->SUPER::DELETE(@_); }

1;

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Kasei, 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
