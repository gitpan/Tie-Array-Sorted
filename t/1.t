use Test::More qw(no_plan);
use_ok("Tie::Array::Sorted");
tie @a, "Tie::Array::Sorted", sub { $_[0] <=> $_[1] };
# Tests look weird because I SUCK.

push @a, 10;
is($a[0], 10, "Stored");
is($a[-1], 10, "Stored");

push @a, 5;
is($a[0], 5, "Sorted");
is($a[-1], 10, "Sorted");

push @a, 15;
is($a[0], 5, "Still sorted");
is($a[1], 10, "Still sorted");
is($a[2], 15, "Still sorted");

push @a, 12;
is($a[0], 5, "Sorted with 12 in there too");
is($a[1], 10, "Sorted with 12 in there too");
is($a[2], 12, "Sorted with 12 in there too");
is($a[3], 15, "Sorted with 12 in there too");

push @a, 10;
is($a[0], 5, "Sorted with duplicates");
is($a[1], 10, "Sorted with duplicates");
is($a[2], 10, "Sorted with duplicates");
is($a[3], 12, "Sorted with duplicates");
is($a[4], 15, "Sorted with duplicates");

pop @a;
is($a[0], 5, "Pop");
is($a[1], 10, "Pop");
is($a[2], 10, "Pop");
is($a[3], 12, "Pop");
is(@a, 4, "Pop");

push @a, 4,5,6;
is("@a", "4 5 5 6 10 10 12", "push");

tie @b, "Tie::Array::Sorted";
push @b, "beta"; is("@b", "beta", "default comparators");
push @b, "alpha"; is("@b", "alpha beta", "default comparators");
push @b, "gamma"; is("@b", "alpha beta gamma", "default comparators");
