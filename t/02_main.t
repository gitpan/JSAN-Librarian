#!/usr/bin/perl -w

# Compile testing for JSAN::Librarian

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}

use Test::More tests => 7;
use Config::Tiny    ();
use JSAN::Librarian ();

# Set paths
my $lib_path      = 't.data';
my $default_index = catfile( 't.data', '.openjsan.deps' );

# Build the example copnfig to compare things to
my $Expected = Config::Tiny->new;
$Expected->{'Foo.js'} = {};
$Expected->{'Bar.js'} = { 'Foo.js' => 1 };
$Expected->{catfile('Foo', 'Bar.js')} = { 'Foo.js' => 1, 'Bar.js' => 1 };





#####################################################################
# Begin Tests

# Check paths and remove as needed
ok( -d $lib_path, 'Lib directory exists' );
unlink $default_index if -e $default_index;
END {
	unlink $default_index if -e $default_index;
}
	
# Build first to check the scanning logic
my $Config = JSAN::Librarian->build_index( $lib_path );
isa_ok( $Config, 'Config::Tiny' );
is_deeply( $Config, $Expected,
	'->build_index returns Config::Tiny that matches expected' );

# Check that make_index writes as expected
ok( JSAN::Librarian->make_index( $lib_path ), '->make_index returns true' );
ok( -e $default_index, '->make_index created index file' );
$Config = Config::Tiny->read( $default_index );
isa_ok( $Config, 'Config::Tiny' );
is_deeply( $Config, $Expected,
	'->make_index returns Config::Tiny that matches expected' );

exit(0);
