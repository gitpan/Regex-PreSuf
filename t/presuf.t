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

foreach my $dict (qw(../ppclinuxwords /usr/dict/words /usr/share/dict/words)) {
    if (open(WORDS, $dict)) {
	while (<WORDS>) {
	    chomp;
	    $words{$_}++;
	}
	close(WORDS);
    }
}

my @words = keys %words;

use Benchmark;

if (@words) {
    print STDERR "# NOTE THAT THIS TEST WILL TAKE SEVERAL MINUTES.\n";
    print STDERR "# And I do mean *SEVERAL* minutes.\n";
    print STDERR "# We will test all the letters from 'a' to 'z',\n";
    print STDERR "# both as the first and the last letters.\n";
    my $ok = 0;
    my @az = ("a".."z");

    # Throw away some of the words.
    @words = grep { /^[a-z]+$/ } @words;

    print STDERR "# Using ", scalar @words, " words.\n";

    my $N0 = 2 * @words;
    my $N1;	
    my $c;
    my @a;
    my @c;
    my $T0 = time();
 
    # I'm trying to get 0 elapsed time to initialize some timesum counters here.
    # Is there a better way?
    my $t1=new Benchmark;
    my $t2=$t1;

    # Initialized to 0, updated by each run of doit.
    my $naiveCreationTotal=timediff($t1,$t2);
    my $naiveExecutionTotal=timediff($t1,$t2);
    my $presufCreationTotal=timediff($t1,$t2);
    my $presufExecutionTotal=timediff($t1,$t2);

    sub doit {
	my ($t0, $t1);
	$t0 = new Benchmark;
	my $b  = join("|", @a);
	$t1 = new Benchmark;
	my $tb = timediff($t1, $t0);
        $naiveCreationTotal=Benchmark::timesum($tb,$naiveCreationTotal);
	print STDERR "# Naïve/create:   ", timestr($tb), "\n";
	print STDERR "# Naïve/execute:  ";
	$t0 = new Benchmark;
	my @b = grep { /^(?:$b)$/ } @words;
	$t1 = new Benchmark;
        $tb=timediff($t1,$t0);
        $naiveExecutionTotal=Benchmark::timesum($tb,$naiveExecutionTotal);
        print STDERR timestr($tb), "\n";
	$t0 = new Benchmark;
	my $c  = presuf(@a);
	$t1 = new Benchmark;
	my $tc = timediff($t1, $t0);
        $presufCreationTotal=Benchmark::timesum($tc,$presufCreationTotal);
	print STDERR "# PreSuf/create:  ", timestr($tc), "\n";
	print STDERR "# PreSuf/execute: ";
	$t0 = new Benchmark;
	@c = grep { /^(?:$c)$/ } @words;
	$t1 = new Benchmark;
        $tc = timediff($t1, $t0);
        $presufExecutionTotal=Benchmark::timesum($tc,$presufExecutionTotal);
        print STDERR timestr($tc), "\n";

	print STDERR "# Aggregate times so far:\n";
	print STDERR "# Naïve/create:   ",timestr($naiveCreationTotal),"\n";
	print STDERR "# Naïve/execute:  ",timestr($naiveExecutionTotal),"\n";
	print STDERR "# Presuf/create:  ",timestr($presufCreationTotal),"\n";
	print STDERR "# PreSuf/execute: ",timestr($presufExecutionTotal),"\n";
    }

    sub checkit {
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
		print STDERR "# MISTOOK:\n";
		foreach (sort keys %c_a) {
		    print STDERR "# $_\n";
		}
	    }
	}
    }

    sub estimateit {
	$N1 += @a;
	my $dt = time() - $T0;
	if ($N1 && $dt) {
	    print STDERR "# Estimated remaining testing time: ",
	                 int(($N0 - $N1)/($N1/$dt)), " seconds.\n";
	}
    }

    foreach $c (@az) {
	@a  = grep { /^$c/  } @words;
	if (@a) {
	    print STDERR "# Testing ", scalar @a," words beginning with '$c'...\n";
	    doit();
	    checkit();
	} else {
	    print STDERR "# No words beginning with '$c'...\n";
	    $ok++; # not a typo
	}
	estimateit();

	@a  = grep { /$c$/  } @words;
	if (@a) {
	    print STDERR "# Testing ", scalar @a," words ending with '$c'...\n";
	    doit();
	    checkit();
	} else{
	    print STDERR "# No words ending with '$c'...\n";
	    $ok++; # not a typo
	}
	estimateit();
    }

    print STDERR "# Aggregate times total:\n";
    print STDERR "# Naïve/create:   ",timestr($naiveCreationTotal),"\n";
    print STDERR "# Naïve/execute:  ",timestr($naiveExecutionTotal),"\n";
    print STDERR "# Presuf/create:  ",timestr($presufCreationTotal),"\n";
    print STDERR "# PreSuf/execute: ",timestr($presufExecutionTotal),"\n";

    print "not " unless $ok == 2 * @az;
    print "ok ", $test++, "\n";
} else {
    print "ok ", $test++, "# skipped: no words found\n";
    print "ok ", $test++, "# skipped: no words found\n";
}
