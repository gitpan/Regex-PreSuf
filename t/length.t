use Regex::PreSuf qw(prefix_length suffix_length);

print "1..24\n";

my $test = 1;

sub tlen {
    my ($sub, $list, $n_want, $diff_want) = @_;

    my ($n, %diff) = $sub->(@$list);
    my @diff = sort keys %diff;
    my $ok = $n == $n_want &&
	     @diff == @$diff_want &&
	     unpack("%32C*", join("\0", @diff)) eq
	     unpack("%32C*", join("\0", @$diff_want));
    print "not " unless $ok;
    print "ok $test";
    $test++;
    print "\n";
    print <<EOF
# expected: $n_want @$diff_want
# got:      $n @diff
EOF
        unless $ok;
}

tlen(\&prefix_length, [qw(foobar foobar)], 6, [qw()]);
tlen(\&prefix_length, [qw(foobar fooxar)], 3, [qw(b x)]);
tlen(\&prefix_length, [qw(foobar foobaz)], 5, [qw(r z)]);
tlen(\&prefix_length, [qw(foobar foozot)], 3, [qw(b z)]);
tlen(\&prefix_length, [qw(foobar feebar)], 1, [qw(e o)]);
tlen(\&prefix_length, [qw(foobar barfoo)], 0, [qw(b f)]);
tlen(\&prefix_length, [qw(foopar fooqar)], 3, [qw(p q)]);
tlen(\&prefix_length, [qw(foopar fooar)],  3, [qw(a p)]);
tlen(\&prefix_length, [qw(o o o o o o o)], 1, [qw()]);
tlen(\&prefix_length, [qw(o o o o o o u)], 0, [qw(o u)]);
tlen(\&prefix_length, [qw(ou ou ou ou ou)],2, [qw()]);
tlen(\&prefix_length, [qw(ou ou ou ou uo)],0, [qw(o u)]);

tlen(\&suffix_length, [qw(foobar foobar)], 6, [qw()]);
tlen(\&suffix_length, [qw(foobar fooxar)], 2, [qw(b x)]);
tlen(\&suffix_length, [qw(foobar goobar)], 5, [qw(f g)]);
tlen(\&suffix_length, [qw(foobar barbar)], 3, [qw(o r)]);
tlen(\&suffix_length, [qw(foobar foober)], 1, [qw(a e)]);
tlen(\&suffix_length, [qw(foobar barfoo)], 0, [qw(o r)]);
tlen(\&suffix_length, [qw(foopar fooqar)], 2, [qw(p q)]);
tlen(\&suffix_length, [qw(foopar fooar)],  2, [qw(o p)]);
tlen(\&suffix_length, [qw(o o o o o o o)], 1, [qw()]);
tlen(\&suffix_length, [qw(o o o o o o u)], 0, [qw(o u)]);
tlen(\&suffix_length, [qw(ou ou ou ou ou)],2, [qw()]);
tlen(\&suffix_length, [qw(ou ou ou ou uo)],0, [qw(o u)]);
