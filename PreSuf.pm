package Regex::PreSuf;

use strict;
local $^W = 1;
use vars qw($VERSION);

$VERSION = "1.02";

=pod

=head1 NAME

Regex::PreSuf - create regular expressions from word lists

=head1 SYNOPSIS

	use Regex::PreSuf;
	
	my $re = presuf(qw(foobar fooxar foozap));

	# $re should be now 'foo(?:zap|[bx]ar)'

=head1 DESCRIPTION

The B<presuf()> subroutine builds regular expressions out of 'word
lists', lists of strings.  The regular expression matches the same
words as the word list.  These regular expressions normally run few
dozen percentages faster than a simple-minded '|'-concatenation of the
word.

Examples:

=over 4

=item *

	'foobar fooxar' => 'foo[bx]ar'

=item *

	'foobar foozap' => 'foo(?:bar|zap)'

=item *

	'foobar fooar'  => 'foob?ar'

=back

The downsides:

=over 4

=item *

The original order of the words is not necessarily respected,
for example because the character class matches are collected
together, separate from the '|' alternations.

=item *

Because the module blithely ignores any specialness of any
regular expression metacharacters such as the C<*?+{}[]>, please
B<do not use> them in the words, the resulting regular expression
will most likely be highly illegal.

=back

For the second downside there is an exception.  The module has some
rudimentary grasp of how to use the 'any character' metacharacter.
If you call B<presuf()> like this:

	my $re = presuf({ anychar=>1 }, qw(foobar foo.ar fooxar));

	# $re should be now 'foo.ar'

The module finds out the common prefixes and suffixes of the words and
then recursively looks at the remaining differences.  However, by
default only common prefixes are used because for many languages
(natural or artificial) this seems to produce the fastest matchers.
To allow also for suffixes use

	my $re = presuf({ suffixes=>1 }, ...);

To use B<only> suffixes use

	my $re = presuf({ prefixes=>0 }, ...);

(this implicitly enables suffixes)

=head2 Prefix and Suffix Length

Two auxiliary subroutines are optionally exportable.  B<WARNING>:
strictly speaking these routines are mainly only intended for internal
use of the module and their interface is subject to change.

=over 4

=item *

	($prefix_length, %diff_chars) = prefix_length(@word_list);

B<prefix_length()> gets a word list and returns the length of the
prefix shared by all the words (such a prefix may not exist, making
the length to be zero), and a hash that has as keys the characters
that made the prefix to "stop".  For example for C<qw(foobar fooxar)>
C<(2, 'b', ..., 'x', ...)> will be returned.

=item *

	($suffix_length, %diff_chars) = suffix_length(@word_list);

B<suffix_length()> gets a word list and returns the length of the
suffix shared by all the words (such a suffix may not exist, making
the length to be zero), and a hash that has as keys the characters
that made the suffix to "stop".  For example for C<qw(foobar barbar)>
C<(3, 'o', ..., 'r', ...)> will be returned.

=back

=head1 COPYRIGHT

Jarkko Hietaniemi

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
    my $param = shift;
    
    return $_[0] if @_ == 1;

    my ($pre_n, %pre_d) = prefix_length @_;
    my ($suf_n, %suf_d) = suffix_length @_;

    print "_presuf: pre_n = $pre_n (",join(" ",%pre_d),")\n";
    print "_presuf: suf_n = $suf_n (",join(" ",%suf_d),")\n";

    my $prefixes =  not exists $param->{ prefixes } ||
	                       $param->{ prefixes };
    my $suffixes =             $param->{ suffixes } ||
	           (    exists $param->{ prefixes } &&
                    not        $param->{ prefixes });

    if ($pre_n or $suf_n) {
	my $ps_n = $pre_n + $suf_n;
	my $ovr_n;

	if ($pre_n == $suf_n) {
	    my $eq_n = 1;

	    foreach (@_[1..$#_]) {
		last if $_[0] ne $_;
		$eq_n++;
	    }

	    return $_[0] if $eq_n == @_; # All equal.  How boring.

	    foreach (@_) {
		my $len = length;

		if ($len < $ps_n) {
		    if (defined $ovr_n){
			$ovr_n = $len if $len < $ovr_n;
		    } else {
			$ovr_n = $len;
		    }
		}
	    }
	}

	# Remove prefixes and suffixes and recurse.

	my $pre_s = substr $_[0], 0,  $pre_n;
	my $suf_s = $suf_n ? substr $_[0], -$suf_n : '';

	print "_presuf: pre_s = $pre_s\n";
	print "_presuf: suf_s = $suf_s\n";

	my @presuf;

	if (defined $ovr_n) {
	    if ($suffixes) {
		$pre_s = "";
		foreach (@_) {
		    my $len = length;
		    push @presuf,
		         $len > $ovr_n ? substr $_, 0, $len - $suf_n : "";
		}
	    } else {
		foreach (@_) {
		    push @presuf, substr $_, $pre_n;
		}
		$suf_s = "";
	    }
	} else {
	    foreach (@_) {
		push @presuf, substr $_, $pre_n, length($_) - $ps_n;
	    }
	}

	print "_presuf: presuf = ",join(":",@presuf),"\n";

	return $pre_s . _presuf($param, @presuf) . $suf_s;
    } else {
	my @len_n;
	my @len_1;
	my $len_0 = 0;
	my (@alt_n, @alt_1);

	foreach (@_) {
	    my $len = length;
	    if    ($len >  1) { push @len_n, $_ }
	    elsif ($len == 1) { push @len_1, $_ }
	    else              { $len_0++        } # $len == 0
	}

	# NOTE: does not preserve the order of the words.

	if (@len_n) {	# Alternation.
	    if (@len_n == 1) {
		@alt_n = @len_n;
	    } else {
		my @pre_d = keys %pre_d;
		my @suf_d = keys %suf_d;

		my (%len_m, @len_m);

		if ($prefixes and $suffixes) {
		    if (@pre_d < @suf_d) {
			$suffixes = 0;
		    } else {
			if (@pre_d == @suf_d) {
			    if ( $param->{ suffixes } ) {
				$prefixes = 0;
			    } else {
				$suffixes = 0;
			    }
			} else {
			    $prefixes = 0;
			}
		    }
		}

		if ($prefixes) {
		    foreach (@len_n) {
			push @{ $len_m{ substr($_, 0, 1) } }, $_;
		    }
		} elsif ($suffixes) {
		    foreach (@len_n) {
			push @{ $len_m{ substr($_, -1  ) } }, $_;
		    }
		}

		foreach (sort keys %len_m) {
		    if (@{ $len_m{ $_ } } > 1) {
			push @alt_n,
                             _presuf($param, @{ $len_m{ $_ } });
		    } else {
			push @alt_n, $len_m{ $_ }->[0];
		    }
		}
	    }
	}

	if (@len_1) { # Character classes.
	    if (exists $param->{ anychar } and
		(exists $pre_d{ '.' } or exists $suf_d{ '.' }) and
	        grep { $_ eq '.' } @len_1) {
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

    _presuf($param, @_);
}

1;
