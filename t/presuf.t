use Regex::PreSuf;

print "1..25\n";

my $test = 1;

sub Tpresuf {
    my ($arg, $want) = @_;

    my ($got) = presuf(@$arg);
    my $ok = $got eq $want;
    shift @$arg if ref $arg->[0] eq 'HASH';
    print <<EOF;
# Test:  $test
# words: @$arg
EOF
    print "not " unless $ok;
    print "ok $test";
    $test++;
    print "\n";
    print <<EOF
# expected: '$want'
EOF
        unless $ok;
    print <<EOF;
# got:      '$got'
EOF
}

Tpresuf([qw(foobar)], 'foobar');
Tpresuf([qw(foopar fooqar)], 'foo[pq]ar');
Tpresuf([qw(foopar fooar)], 'foop?ar');
Tpresuf([qw(foopar fooqar fooar)], 'foo[pq]?ar');
Tpresuf([qw(foobar foozap)], 'foo(?:bar|zap)');
Tpresuf([qw(foobar foobarzap)], 'foobar(?:zap)?');
Tpresuf([qw(foobar barbar)], '(?:bar|foo)bar');
Tpresuf([qw(and at do end for in is not of or use)], '(?:a(?:nd|t)|do|end|for|i[ns]|not|o[fr]|use)');

Tpresuf([{anychar=>1}, qw(foobar foob.r)], 'foob.r');
Tpresuf([{anychar=>1}, qw(bar br .r)], '(?:ba|.)r');

Tpresuf([qw(abc abe adc bac)],'(?:a(?:b[ce]|dc)|bac)');
Tpresuf([{suffixes=>1},qw(abc abe adc bac)],'(?:(?:a[bd]|ba)c|abe)');
Tpresuf([{prefixes=>0},qw(abc abe adc bac)],'(?:(?:ba|ab|ad)c|abe)');

Tpresuf([
        qw(.perl p.erl pe.rl per.l perl. pel .erl erl per. per p.rl prl pe.l)],
        '(?:\.p?erl|erl|p(?:\.e?rl|e(?:\.r?l|r(?:\.l|l\.|\.)|[lr])|rl))');
Tpresuf([{anychar=>1},
        qw(.perl p.erl pe.rl per.l perl. pel .erl erl per. per p.rl prl pe.l)],
        '(?:.p?erl|erl|p(?:.e?rl|e(?:.r?l|r(?:.l|l.|.)|[lr])|rl))');

# The following tests suggested and inspired by Mark Kvale.
Tpresuf([qw(aba a)], 'a(?:ba)?');
Tpresuf([{suffixes=>1},qw(aba a)], '(?:ab)?a');
Tpresuf([qw(ababa aba)], 'aba(?:ba)?');
Tpresuf([qw(aabaa a)], 'a(?:abaa)?');
Tpresuf([qw(aabaa aa)], 'aa(?:baa)?');
Tpresuf([qw(aabaa aaa)], 'aa(?:ba)?a');
Tpresuf([qw(aabaa aaaa)], 'aab?aa');

# The following tests presented by Mike Giroux.
Tpresuf([qw(rattle rattlesnake)], 'rattle(?:snake)?');
Tpresuf([qw(rata ratepayer rater)], 'rat(?:e(?:paye)?r|a)');

print STDERR "# Hang on, collecting words for the next test...\n";

my %words;

foreach my $dict (qw(/usr/dict/words /usr/share/dict/words)) {
    if (open(WORDS, $dict)) {
	while (<WORDS>) {
	    chomp;
	    $words{$_}++;
	}
	close(WORDS);
    }
}

my @words = keys %words;

print STDERR "# Got ", scalar @words, " words.\n";

use Benchmark;

if (@words) {
    print STDERR "# NOTE THAT THIS TEST WILL TAKE SEVERAL MINUTES.\n";
    print STDERR "# WE WILL TEST ALL THE LETTERS FROM 'a' TO 'z'.\n";
    my $ok;
    my @az = ("a".."z");
    foreach my $c (@az) {
	my @a  = grep { /^$c/  } @words;
	my ($t0, $t1);
	print STDERR "# Testing ", scalar @a," words beginning with '$c'...\n";
	$t0 = new Benchmark;
	my $b  = join("|", @a);
	$t1 = new Benchmark;
	my $tb = timediff($t1, $t0);
	print STDERR "# Naïve/create:   ", timestr($tb), "\n";
	print STDERR "# Naïve/execute:  ";
	$t0 = new Benchmark;
	my @b = grep { /^(?:$b)$/ } @words;
	$t1 = new Benchmark;
	print STDERR timestr(timediff($t1, $t0)), "\n";
	$t0 = new Benchmark;
	my $c  = presuf(@a);
	$t1 = new Benchmark;
	my $tc = timediff($t1, $t0);
	print STDERR "# PreSuf/create:  ", timestr($tc), "\n";
	print STDERR "# PreSuf/execute: ";
	$t0 = new Benchmark;
	my @c = grep { /^(?:$c)$/ } @words;
	$t1 = new Benchmark;
	print STDERR timestr(timediff($t1, $t0)), "\n";
	if (@c == @a && join("\0", @a) eq join("\0", @c)) {
	    $ok++;
	} else {
	    print STDERR "# PreSuf FAILED!\n";
	    my %a; @a{@a} = ();
	    my %c; @c{@c} = ();
	    my %a_c = %a; delete @a_c{keys %c};
	    my %c_a = %c; delete @c_a{keys %a};
	    if (keys %a_c) {
		print STDERR "# MISSED:\n";
		foreach (sort keys %a_c) {
		    print STDERR "# $_\n";
		}
	    }
	    if (keys %c_a) {
		print STDERR "# INVENTED:\n";
		foreach (sort keys %c_a) {
		    print STDERR "# $_\n";
		}
	    }
	}
    }
    print "not " unless $ok == @az;
    print "ok ", $test++, "\n";
} else {
    print "ok ", $test++, "# skipped: no words found\n";
}
