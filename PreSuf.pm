package Regex::PreSuf;

use strict;
local $^W = 1;
use vars qw($VERSION);

$VERSION = 0.002;

=pod

=head1 NAME

Regex::PreSuf - create regular expressions from word lists

=head1 SYNOPSIS

	use Regex::PreSuf;
	
	my $re = presuf(qw(foobar fooxar foozap));

	# $re should be now 'foo(?:zap|[bx]ar)'

=head1 DESCRIPTION

This module creates regular expressions out of 'word lists', lists
of strings, matching the same words.  The easiest thing to do would
be of course just to concatenate the words with '|' but this module
tries to be cleverer.  It finds out the common prefixes and suffixes
of the words and then recursively looks at the remaining differences.
It knows about character classes.  These optimized regular expressions
normally run few dozen percentages faster than the simple-minded
'|'-concatenation.

The downsides:

=over 4

=item the original order of the words is not necessarily
respected, for example because the character class matches are be
collected together, separate from the '|' alternations.

=item because the module blithely ignores any specialness of any
regular expression metacharacters such as the C<*?+{}[]>, please
B<do not use> them in the words, the resulting regular expression
will most likely be illegal

=back

For the second downside there is an exception.  The module has some
rudimentary grasp of what to do with the 'any character'
metacharacter.  If you call C<presuf()> like this:

	my $re = presuf({ anychar=>1 }, qw(foobar foo.ar fooxar));

	# $re should be now 'foo.ar'

Beware, though, there are limits to the grasp:

	my $re = presuf({ anychar=>1 }, qw(foobar foo.ar fooxa.));

	# $re _could_ be now 'foo.a.'
        # but it is 'foo(?:xa.|.ar)'

Finesses like this may or may not be implemented in future releases.

=head1 COPYRIGHT

Jarkko Hietaniemi F<E<lt>jhi@iki.fiE<gt>>

This code is distributed under the same copyright terms as Perl itself.

=cut

use vars qw(@ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(presuf);
@EXPORT_OK = qw(prefix_length suffix_length);

sub prefix_length {
    my $n = 0;
    my %diff;

    for(my $m = 0; ; $m++) {
	foreach (@_) {
            $diff{ length($_) <= $m ? '' : substr($_, $m, 1) }++;
	}
        last if keys %diff > 1;
	if (exists $diff{ '' } and $diff{ '' } == @_) {
	    %diff = ();
	    last;
	}
	%diff = ();
        $n = $m+1;
    }

    return ($n, %diff);
}

sub suffix_length {
    my $n = 0;
    my %diff;

    for(my $m = 1; ; $m++) {
	foreach (@_){
	    $diff{ length($_) < $m ? '' : substr($_, -$m, 1)}++;
	}
        last if keys %diff > 1;
	if (exists $diff{ '' } and $diff{ '' } == @_) {
	    %diff = ();
	    last;
	}
        %diff = ();
        $n = $m;
    }

    return ($n, %diff);
}

sub _presuf {
    my $level = shift;
    my $param = shift;
    my ($pre_n, %pre_d) = prefix_length @_;
    my ($suf_n, %suf_d) = suffix_length @_;

    if ($pre_n or $suf_n) {
	return $_[0] if $pre_n == $suf_n; # Really?  All equal?

	# Remove prefixes and suffixes and recurse.

	my $pre_s = substr $_[0], 0,  $pre_n;
	my $suf_s = $suf_n ? substr $_[0], -$suf_n : '';

	my @presuf;

	my $rem_n = $pre_n + $suf_n;

	foreach (@_) {
	    push @presuf, substr $_, $pre_n, length($_) - $rem_n;
	}

	return $pre_s . _presuf($level + 1, $param, @presuf) . $suf_s;
    } else {
	my @len_n;
	my @len_1;
	my $len_0 = 0;
	my (@alt_n, @alt_1);

	foreach (@_) {
	    my $len = length;
	    if    ($len >  1) { push @len_n, $_ }
	    elsif ($len == 1) { push @len_1, $_ }
	    else              { $len_0 = 1      } # $len == 0
	}

	# NOTE: does not preserve the order of |.

	if (@len_n) {	# Alternation.
	    if (@len_n == 1) {
		@alt_n = @len_n;
	    } else {
		my @pre_d = keys %pre_d;
		my @suf_d = keys %suf_d;

		my (%len_m, @len_m);

		if (@pre_d <= @suf_d) {
		    foreach (@len_n) {
			push @{ $len_m{ substr($_, 0, 1) } }, $_;
		    }
		} else {
		    foreach (@len_n) {
			push @{ $len_m{ substr($_, -1  ) } }, $_;
		    }
		}

		foreach (sort keys %len_m) {
		    if (@{ $len_m{ $_ } } > 1) {
			push @alt_n,
                             _presuf($level + 1, $param, @{ $len_m{ $_ } });
		    } else {
			push @alt_n, $len_m{ $_ }->[0];
		    }
		}
	    }
	}

	if (@len_1) {
	    if (exists $param->{ anychar } and
		(exists $pre_d{ '.' } or exists $suf_d{ '.'})) {
		push @alt_1, '.';
	    } else {
		if (@len_1 == 1) {
		    push @alt_1, $len_1[0];
		} else {
		    push @alt_1, join('', '[', @len_1, ']' );
		}
	    }
	}

	my $alt = join('|', @alt_n, @alt_1);

	$alt = '(?:' . $alt . ')' unless @alt_n == 0;

	$alt .= '?' if $len_0;

	return $alt;
    }
}

sub presuf {
    my $param = ref $_[0] eq 'HASH' ? shift : { };

    _presuf(0, $param, @_);
}

1;
