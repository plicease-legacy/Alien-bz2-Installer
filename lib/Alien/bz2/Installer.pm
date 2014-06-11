package Alien::bz2::Installer;

use strict;
use warnings;

# ABSTRACT: Installer for bz2
# VERSION

sub _catfile {
  my $path = File::Spec->catfile(@_);
  $path =~ s{\\}{/}g if $^O eq 'MSWin32';
  $path;
}

sub _catdir {
  my $path = File::Spec->catdir(@_);
  $path =~ s{\\}{/}g if $^O eq 'MSWin32';
  $path;
}

=head1 CLASS METHODS

=head2 versions_available

 my @versions = Alien::bz2::Installer->versions_available;
 my $latest_version = $version[-1];

Returns the list of versions of bzip2 available on the Internet.
Will throw an exception if available versions cannot be determined.

=cut

sub versions_available
{
  ($^O eq 'MSWin32' ? '1.0.5' : '1.0.6');
}

=head2 fetch

 my($location, $version) = Alien::bz2::Installer->fetch(%options);
 my $location = Alien::bz2::Installer->fetch(%options);

B<NOTE:> using this method may (and probably does) require modules
returned by the L<build_requires|Alien::bz2::Installer#build_requires>
method.

Download the bz2 source from the internet.  By default it will
download the latest version t a temporary directory, which will
be removed when Perl exits.  Will throw an exception on failure.
Options include:

=over 4

=item dir

Directory to download to

=item version

Version to download

=back

=cut

sub fetch
{
  my($class, %options) = @_;
  
  my $dir = $options{dir} || eval { require File::Temp; File::Temp::tempdir( CLEANUP => 1 ) };
  
  # actually we ignore the version argument.

  require File::Spec;
  
  my $url      = 'http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz';
  my $fn       = _catfile($dir, 'bzip2-1.0.6.tar.gz');
  my($version) = $class->versions_available;
  if($^O eq 'MSWin32')
  {
    $url = 'http://gnuwin32.sourceforge.net/downlinks/bzip2-src-zip.php';
    $fn  = _catfile($dir, 'bzip2-1.0.5-src.zip');
  }
  
  require HTTP::Tiny;
  my $response = HTTP::Tiny->new->get($url);
  
  die sprintf("%s %s %s", $response->{status}, $response->{reason}, $url)
    unless $response->{success};

  open my $fh, '>', $fn;
  binmode $fh;
  print $fh $response->{content};
  close $fh;
  
  wantarray ? ($fn, $version) : $fn;
}

=head2 build_requires

 my $prereqs = Alien::bz2::Installer->build_requires;
 while(my($module, $version) = each %$prereqs)
 {
   ...
 }

Returns a hash reference of the build requirements.  The
keys are the module names and the values are the versions.

The requirements may be different depending on your platform.

=cut

sub build_requires
{
  my %prereqs = (
    'HTTP::Tiny' => 0,
  );
  
  if($^O eq 'MSWin32')
  {
    $prereqs{'Archive::Zip'} = 0;
  }
  else
  {
    $prereqs{'Archive::Tar'} = 0;
  }
  
  \%prereqs;
}

=head2 system_requires

This is like L<build_requires|Alien::bz2::Installer#build_requires>,
except it is used when using the bz2 that comes with the operating
system.

=cut

sub system_requires
{
  my %prereqs;
  \%prereqs;
}

=head2 system_install

 my $installer = Alien::bz2::Installer->system_install(%options);

B<NOTE:> using this method may require modules returned by the
L<system_requires|Alien::bz2::Installer> method.

Options:

=over 4

=item test

Specifies the test type that should be used to verify the integrity
of the system bz2.  Generally this should be
set according to the needs of your module.  Should be one of:

=over 4

=item compile

use L<test_compile_run|Alien::bz2::Installer#test_compile_run> to verify.
This is the default.

=item ffi

use L<test_ffi|Alien::bz2::Installer#test_ffi> to verify

=item both

use both
L<test_compile_run|Alien::bz2::Installer#test_compile_run>
and
L<test_ffi|Alien::bz2::Installer#test_ffi>
to verify

=back

=item alien

If true (The default) then an existing L<Alien::bz2> will
be used if found.  Usually this is what you want.

=back

=cut

sub system_install
{
  my($class, %options) = @_;
  
  $options{alien} = 1 unless defined $options{alien};
  $options{test} ||= 'compile';
  die "test must be one of compile, ffi or both"
    unless $options{test} =~ /^(compile|ffi|both)$/;
   
  my $build = bless {
    cflags => [],
    libs   => ['-lbz2'],
  }, $class;
  
  $build->test_compile_run || die $build->error if $options{test} =~ /^(compile|both)$/;
  $build->test_ffi || die $build->error if $options{test} =~ /^(ffi|both)$/;
  $build;
}

# TODO: build_install

=head1 ATTRIBUTES

Attributes of an L<Alien::bz2::Installer> provide the
information needed to use an existing bz2 (which may
either be provided by the system, or have just been built
using L<build_install|Alien::bz2::Installer#build_install>.

=head2 cflags

The compiler flags required to use bz2.

=head2 libs

The linker flags and libraries required to use bz2.

=head2 dlls

List of DLL or .so (or other dynamic library) files that can
be used by L<FFI::Raw> or similar.

=head2 version

The version of bz2

=cut

sub cflags  { shift->{cflags}  }
sub libs    { shift->{libs}    }
sub version { shift->{version} }

sub dlls
{
  my($self, $prefix) = @_;
  
  $prefix = $self->{prefix} unless defined $prefix;
  
  require File::Spec;
  
  unless(defined $self->{dlls} && defined $self->{dll_dir})
  {
    require DynaLoader;
    my $path = DynaLoader::dl_findfile(grep /^-l/, @{ $self->libs});
    die "unable to find dynamic library" unless defined $path;
    my($vol, $dirs, $file) = File::Spec->splitpath($path);
    if($^O eq 'openbsd')
    {
      # on openbsd we get the .a file back, so have to scan
      # for .so.#.# as there is no .so symlink
      opendir(my $dh, $dirs);
      $self->{dlls} = [grep /^libbz2.so/, readdir $dh];
      closedir $dh;
    }
    else
    {
      $self->{dlls} = [ $file ];
    }
    $self->{dll_dir} = [];
    $prefix = File::Spec->catpath($vol, $dirs);
    $prefix =~ s{\\}{/}g;
  }
  
  map { _catfile($prefix, @{ $self->{dll_dir} }, $_) } @{ $self->{dlls} };
}

=head1 INSTANCE METHODS

=head2 test_compile_run

 if($installer->test_compile_run(%options))
 {
   # You hae a working bz2
 }
 else
 {
   die $installer->error;
 }

Tests the compiler to see if you can build and run
a simple bz2 program.  On success it will 
return the bz2 version.  Other options include

=over 4

=item cbuilder

The L<ExtUtils::CBuilder> instance that you want
to use.  If not specified, then a new one will
be created.

=item dir

Directory to use for building the executable.
If not specified, a temporary directory will be
created and removed when Perl terminates.

=back

=cut

sub test_compile_run
{
  my($self, %opt) = @_;
  
  delete $self->{error};
  my $cbuilder = $opt{cbuilder} || do { require ExtUtils::CBuilder; ExtUtils::CBuilder->new(quiet => 1) };
  
  unless($cbuilder->have_compiler)
  {
    $self->{error} = 'no compiler';
    return;
  }
  
  my $dir = $opt{dir} || do { require File::Temp; File::Temp::tempdir(CLEANUP => 1) };
  require File::Spec;
  my $fn = _catfile($dir, 'test.c');
  do {
    open my $fh, '>', $fn;
    print $fh "#include <bzlib.h>\n",
              "#include <stdio.h>\n",
              "int\n",
              "main(int argc, char *argv[])\n",
              "{\n",
              "  printf(\"version = '%s'\\n\", BZ2_bzlibVersion());\n",
              "  return 0;\n",
              "}\n";
    close $fh;
  };
  
  my $test_exe = eval {
    my $test_object = $cbuilder->compile(
      source               => $fn,
      extra_compiler_flags => $self->cflags,
    );
    $cbuilder->link_executable(
      objects            => $test_object,
      extra_linker_flags => $self->libs,
    );
  };

  if(my $error = $@)
  {
    $self->{error} = $error;
    return;
  }
  
  if($test_exe =~ /\s/)
  {
    $test_exe = Win32::GetShortPathName($test_exe) if $^O eq 'MSWin32';
    $test_exe = Cygwin::win_to_posix_path(Win32::GetShortPathName(Cygwin::posix_to_win_path($test_exe))) if $^O eq 'cygwin';
  }
  
  my $output = `$test_exe`;

  if($?)
  {
    if($? == -1)
    {
      $self->{error} = "failed to execute $!";
    }
    elsif($? & 127)
    {
      $self->{error} = "child died with signal" . ($? & 127);
    }
    elsif($?)
    {
      $self->{error} = "child exited with value " . ($? >> 8);
    }
    return;
  }
  
  if($output =~ /version = '(.*?),/)
  {
    return $self->{version} = $1;
  }
  else
  {
    $self->{error} = "unable to retrieve version from output";
    return;
  }
}

=head2 test_ffi

 if($installer->test_ffi(%options))
 {
   # You have a working bz2
 }
 else
 {
   die $installer->error;
 }

Test bz2 to see if it can be used with L<FFI::Raw> (or similar).
On success, it will return the bz2 version.

=cut

sub test_ffi
{
  my($self) = @_;
  require FFI::Raw;
  
  foreach my $dll ($self->dlls)
  {
    my $get_version = eval {
      FFI::Raw->new(
        $dll, 'BZ2_bzlibVersion', FFI::Raw::str(),
      );
    };
    next if $@;
    if($get_version->() =~ /^(.*?),/)
    {
      return $self->{version} = $1;
    }
  }
  $self->{error} = 'BZ2_bzlibVersion not found';
  return;
}

=head2 error

Returns the error from the previous call to L<test_compile_run|Alien::bz2::Installer#test_compile_run>
or L<test_ffi|Alien::bz2::Installer#test_ffi>.

=cut

sub error { $_[0]->{error} }

1;
