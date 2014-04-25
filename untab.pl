#!/usr/bin/perl -w
#---------------------------------------------------------------------------------------------
# untab.pl - reduced tabbed data into multi-dimensional facts
#
# Usage : [perl.exe] untab.pl infile.txt [ >outfile.txt ]
#
# Assumptions:
#	- input data is tabular with fixed number of columns
#	- Non-dimensional values are quantitative with no trailing qualifiers
#	- Non-dimensional values can have leading currency qualifiers, currently £ or $
#---------------------------------------------------------------------------------------------
use strict;
use Tie::File;
use Fcntl 'O_RDONLY';


my $separators = "\t,.-"; # This represents a sequential list of separator characters
my $data_regex = '^[£\$]?\s*[\d.,]*$'; # This regex represents the entire contents of a cell

# Open specified file
my $infile = $ARGV[0];
tie my @file, 'Tie::File', $infile, mode => O_RDONLY or die "Cannot open file $infile: $!";

# First pass - grab separator and every column count
my $sep;
my $colcounts;
my @cols;
for (@file) {
	# Grab separator
	if (!$sep) {
		for (split //, $separators) {
			if ($file[$#file] =~ /$_/) {
				$sep = $_;
				last;
			}
		}
	}
	@cols = split /$sep/;
	$colcounts->{@cols}++;
}

# -- Validate columns
my $colcount = keys %{$colcounts};
if ($colcount > 1) {
	print STDERR "Mixed columns keys:\n";
	for my $count(keys %{$colcounts}) {
		print STDERR "\t$count\t$colcounts->{$count}\n";
	}
	die;
}

# -- Find last dimension column
my $lastdim = $#cols;
for (reverse @cols) {
	if (/$data_regex/) {
		$lastdim--;
	} else {
		last;
	}
}

# Process the data
my @headers;
for (@file) {
	my @data = split /$sep/;
	if (!@headers) {
		push @headers, @data;
		for my $idx (0..$lastdim) {
			if ($idx > 0) {
				print $sep;
			}
			print $headers[$idx];
		}
		print "${sep}Topline${sep}Data\n";
	} else {
		my $dimensions;
		for my $idx (0..$#headers) {
			# Process dimensions
			if ($idx <= $lastdim) {
				if ($idx > 0) {
					$dimensions .= $sep;
				}
				$dimensions .= $data[$idx];
			} else {
				if ($data[$idx] gt '') {
					print "$dimensions$sep$headers[$idx]$sep$data[$idx]\n"
				}
			}
		}
	}
}
untie @file;