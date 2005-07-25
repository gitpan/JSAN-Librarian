package JSAN::Librarian;

=pod

=head1 NAME

JSAN::Librarian - JavaScript::Librarian adapter for a JSAN installation

=head1 DESCRIPTION

L<JavaScript::Librarian> works on the concept of "libraries" of JavaScript
files each of which may depend on other files to be loaded before them.

C<JSAN::Librarian> provides a mechanism for detecting and indexing a
L<JavaScript::Librarian::Library> object for a L<JSAN> installation.

=head1 METHODS

=cut

use strict;
use Carp                     ();
use Config::Tiny             ();
use File::Spec               ();
use File::Path               ();
use File::Basename           ();
use File::Find::Rule         ();
use JSAN::Parse::FileDeps    ();
use constant 'FFR' => 'File::Find::Rule';

use vars qw{$VERSION $VERBOSE};
BEGIN {
	$VERSION = '0.01';
	$VERBOSE ||= 0;
}





#####################################################################
# JSAN::Librarian Methods

=pod

=head2 make_index $lib [, $index_file ]

The C<make_index> static method scans an installed L<JSAN> lib tree
and builds a L<Config::Tiny> index containing the file-level dependency
information for the files in the library.

The first parameter should be the root path of the library, with an
optional second parameter of the index file to write to. If not provided,
the index file will be written at C<$lib/.openjsan.deps>.

Returns true on succuess, or throws an exception on error.

=cut

sub make_index {
	my $class  = shift;
	my $root   = (defined $_[0] and -d $_[0]) ? shift : return undef;
	my $output = @_ ? shift : File::Spec->catfile( $root, '.openjsan.deps' );

	# Make sure the output path exists
	my $dir = File::Basename::dirname( $output );
	unless ( -d $dir ) {
		eval { File::Path::mkpath( $dir, $VERBOSE ); };
		Carp::croak("$!: Failed to mkdir '$dir' for JSAN::Librarian index file") if $@;
	}

	# Generate the Config::Tiny object
	my $Config = $class->build_index( $root );

	print "Writing $output\n" if $VERBOSE;
	$Config->write( $output )
		or Carp::croak("Failed to write JSAN::Librarian index file '$output'");
}

=pod

=head2 build_index $lib

The C<build_index> method implements the same functionality as the main
C<make_index> method, except that it takes only the lib path, and returns
the L<Config::Tiny> object directly, instead of writing it to the index file.

Returns a L<Config::Tiny> object, or throws an exception on error.

=cut

sub build_index {
	my $class  = shift;
	my $root   = (defined $_[0] and -d $_[0]) ? shift : return undef;

	# Create the Config::Tiny objecy
	my $Config = Config::Tiny->new;

	# Find all the files
	print "Searching $root...\n" if $VERBOSE;
	my @files = FFR->relative->file->name('*.js')->not_name(qr/_deps\.js$/)->in( $root );
	foreach my $js ( @files ) {
		$Config->{$js} = {};
		my $path = File::Spec->catfile( $root, $js );
		print "Scanning $js\n" if $VERBOSE;
		my @deps = JSAN::Parse::FileDeps->file_deps( $path );
		foreach ( @deps ) {
			$Config->{$js}->{$_} = 1;
		}
	}

	$Config;
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSAN-Librarian>

For other issues, contact the maintainer

=head1 AUTHORS

Adam Kennedy <cpan@ali.as>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
