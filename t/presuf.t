use Regex::PreSuf;

print "1..15\n";

my $test = 1;

sub Tpresuf {
    my ($arg, $want) = @_;

    my ($got) = presuf(@$arg);
    my $ok = $got eq $want;
    print "not " unless $ok;
    print "ok $test";
    $test++;
    print "\n";
    print <<EOF
# expected: '$want'
# got:      '$got'
EOF
        unless $ok;
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
        '(?:.p?erl|erl|p(?:.e?rl|e(?:.r?l|r(?:.l|l.|.)|[lr])|rl))');
Tpresuf([{anychar=>1},
        qw(.perl p.erl pe.rl per.l perl. pel .erl erl per. per p.rl prl pe.l)],
        '(?:.p?erl|erl|p(?:.e?rl|e(?:.r?l|r(?:.l|l.|.)|[lr])|rl))');

