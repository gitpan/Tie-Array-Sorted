package Tie::Array::Sorted;
use base 'Tie::Array';
use 5.006;
use strict;
use warnings;
our $VERSION = '1.0';

=head1 NAME

Tie::Array::Sorted - An array which is kept sorted

=head1 SYNOPSIS

  use Tie::Array::Sorted;
  tie @a, "Tie::Array::Sorted";
  push @a, 10, 4, 7, 3, 4;
  print "@a"; # "3 4 4 7 10"

=head1 DESCRIPTION

This presents an ordinary array, but is kept sorted. All pushes and
unshifts cause the elements in question to be inserted in the
appropriate location to maintain order.

Direct stores (C<$a[10] = "wibble">) effectively splice out the original
value and insert the new element. It's not clear why you'd want to use
direct stores like that, but this module does the right thing if you do.

If you don't like the ordinary numeric comparator, you can provide your
own; it should compare the two elements it is given:

    tie @a, "tie::Array::Sorted", sub { $_[0] cmp $_[1] }

=cut

sub TIEARRAY  { 
    my ($class, $comparator) = @_;
    bless {
        array => [],
        comp  => (defined $comparator ? $comparator : sub { $_[0] <=> $_[1] })
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

1;

=head1 AUTHOR

Simon Cozens, E<lt>simon@kasei.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Kasei

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
