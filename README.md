# Alien::bz2::Installer

Installer for bz2

# SYNOPSIS

Build.PL

    # as an optional dep
    use Alien::bz2::Installer;
    use Module::Build;
    
    my %build_args;
    
    my $installer = eval { Alien::bz2::Installer->system_install };
    if($installer)
    {
      $build_args{extra_compiler_flags} = $installer->cflags,
      $build_args{extra_linker_flags}   = $installer->libs,
    }
    
    my $build = Module::Build->new(%build_args);
    $build->create_build_script;

Build.PL

    # require 3.0
    use Alien::bz2::Installer;
    use Module::Build;
    
    my $installer = eval {
      my $system_installer = Alien::bz2::Installer->system_install;
      die "we require 1.0.6 or better"
        if $system->version !~ /^([0-9]+)\.([0-9]+)\.([0-9]+)/ && $1 >= 1 && ($3 >= 6 || $1 > 1);
      $system_installer;
         # reasonably assumes that build_install will never download
         # a version older that 1.0.6
    } || Alien::bz2::Installer->build_install("dir");
    
    my $build = Module::Build->new(
      extra_compiler_flags => $installer->cflags,
      extra_linker_flags   => $installer->libs,
    );
    $build->create_build_script;

FFI::Raw

    # as an optional dep
    use Alien::bz2::Installer;
    use FFI::Raw;
    
    eval {
      my($dll) = Alien::bz2::Installer->system_install->dlls;
      FFI::Raw->new($dll, 'BZ2_bzlibVersion', FFI::Raw::str);
    };
    if($@)
    {
      # handle it if bz2 is not available
    }

# DESCRIPTION

If you just want to compress or decompress bzip2 data in Perl you
probably want one of [Compress::Bzip2](https://metacpan.org/pod/Compress::Bzip2), [Compress::Raw::Bzip2](https://metacpan.org/pod/Compress::Raw::Bzip2)
or [IO::Compress::Bzip2](https://metacpan.org/pod/IO::Compress::Bzip2).

This distribution contains the logic for finding existing bz2
installs, and building new ones.  If you do not care much about the
version of bz2 that you use, and bz2 is not an optional
requirement, then you are probably more interested in using
[Alien::bz2](https://metacpan.org/pod/Alien::bz2).

Where [Alien::bz2::Installer](https://metacpan.org/pod/Alien::bz2::Installer) is useful is when you have
specific version requirements (say you require 3.0.x but 2.7.x
will not do), but would still like to use the system bz2
if it is available.

# CLASS METHODS

Class methods can be executed without creating an instance of
[Alien::bz2::Installer](https://metacpan.org/pod/Alien::bz2::Installer), and generally used to query
status of bz2 availability (either via the system or the
internet).  Methods that discover a system bz2 or build
a one from source code on the Internet will generally return
an instance of [Alien::bz2::Installer](https://metacpan.org/pod/Alien::bz2::Installer) which can be
queried to retrieve the settings needed to interact with 
bz2 via XS or [FFI::Raw](https://metacpan.org/pod/FFI::Raw).

## versions\_available

    my @versions = Alien::bz2::Installer->versions_available;
    my $latest_version = $version[-1];

Returns the list of versions of bzip2 available on the Internet.
Will throw an exception if available versions cannot be determined.

## fetch

    my($location, $version) = Alien::bz2::Installer->fetch(%options);
    my $location = Alien::bz2::Installer->fetch(%options);

**NOTE:** using this method may (and probably does) require modules
returned by the [build\_requires](https://metacpan.org/pod/Alien::bz2::Installer#build_requires)
method.

Download the bz2 source from the internet.  By default it will
download the latest version t a temporary directory, which will
be removed when Perl exits.  Will throw an exception on failure.
Options include:

- dir

    Directory to download to

- version

    Version to download

## build\_requires

    my $prereqs = Alien::bz2::Installer->build_requires;
    while(my($module, $version) = each %$prereqs)
    {
      ...
    }

Returns a hash reference of the build requirements.  The
keys are the module names and the values are the versions.

The requirements may be different depending on your platform.

## system\_requires

This is like [build\_requires](https://metacpan.org/pod/Alien::bz2::Installer#build_requires),
except it is used when using the bz2 that comes with the operating
system.

## system\_install

    my $installer = Alien::bz2::Installer->system_install(%options);

**NOTE:** using this method may require modules returned by the
[system\_requires](https://metacpan.org/pod/Alien::bz2::Installer) method.

Options:

- test

    Specifies the test type that should be used to verify the integrity
    of the system bz2.  Generally this should be
    set according to the needs of your module.  Should be one of:

    - compile

        use [test\_compile\_run](https://metacpan.org/pod/Alien::bz2::Installer#test_compile_run) to verify.
        This is the default.

    - ffi

        use [test\_ffi](https://metacpan.org/pod/Alien::bz2::Installer#test_ffi) to verify

    - both

        use both
        [test\_compile\_run](https://metacpan.org/pod/Alien::bz2::Installer#test_compile_run)
        and
        [test\_ffi](https://metacpan.org/pod/Alien::bz2::Installer#test_ffi)
        to verify

- alien

    If true (The default) then an existing [Alien::bz2](https://metacpan.org/pod/Alien::bz2) will
    be used if found.  Usually this is what you want.

## build\_install

    my $installer = Alien::bz2::Installer->build_install( '/usr/local', %options );

**NOTE:** using this method may (and probably does) require modules
returned by the [build\_requires](https://metacpan.org/pod/Alien::bz2::Installer)
method.

Build and install bz2 into the given directory.  If there
is an error an exception will be thrown.  On a successful build, an
instance of [Alien::bz2::Installer](https://metacpan.org/pod/Alien::bz2::Installer) will be returned.

These options may be passed into build\_install:

- tar

    Filename where the bz2 source tar is located.
    If not specified the latest version will be downloaded
    from the Internet.

- dir

    Empty directory to be used to extract the bz2
    source and to build from.

- test

    Specifies the test type that should be used to verify the integrity
    of the build after it has been installed.  Generally this should be
    set according to the needs of your module.  Should be one of:

    - compile

        use [test\_compile\_run](https://metacpan.org/pod/Alien::bz2::Installer#test_compile_run) to verify.
        This is the default.

    - ffi

        use [test\_ffi](https://metacpan.org/pod/Alien::bz2::Installer#test_ffi) to verify

    - both

        use both
        [test\_compile\_run](https://metacpan.org/pod/Alien::bz2::Installer#test_compile_run)
        and
        [test\_ffi](https://metacpan.org/pod/Alien::bz2::Installer#test_ffi)
        to verify

# ATTRIBUTES

Attributes of an [Alien::bz2::Installer](https://metacpan.org/pod/Alien::bz2::Installer) provide the
information needed to use an existing bz2 (which may
either be provided by the system, or have just been built
using [build\_install](https://metacpan.org/pod/Alien::bz2::Installer#build_install).

## cflags

The compiler flags required to use bz2.

## libs

The linker flags and libraries required to use bz2.

## dlls

List of DLL or .so (or other dynamic library) files that can
be used by [FFI::Raw](https://metacpan.org/pod/FFI::Raw) or similar.

## version

The version of bz2

# INSTANCE METHODS

## test\_compile\_run

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

- cbuilder

    The [ExtUtils::CBuilder](https://metacpan.org/pod/ExtUtils::CBuilder) instance that you want
    to use.  If not specified, then a new one will
    be created.

- dir

    Directory to use for building the executable.
    If not specified, a temporary directory will be
    created and removed when Perl terminates.

- quiet

    Passed into [ExtUtils::CBuilder](https://metacpan.org/pod/ExtUtils::CBuilder) if you do not
    provide your own instance.  The default is true
    (unlike [ExtUtils::CBuilder](https://metacpan.org/pod/ExtUtils::CBuilder) itself).

## test\_ffi

    if($installer->test_ffi(%options))
    {
      # You have a working bz2
    }
    else
    {
      die $installer->error;
    }

Test bz2 to see if it can be used with [FFI::Raw](https://metacpan.org/pod/FFI::Raw) (or similar).
On success, it will return the bz2 version.

## error

Returns the error from the previous call to [test\_compile\_run](https://metacpan.org/pod/Alien::bz2::Installer#test_compile_run)
or [test\_ffi](https://metacpan.org/pod/Alien::bz2::Installer#test_ffi).

# SEE ALSO

- [Alien::bz2](https://metacpan.org/pod/Alien::bz2)
- [Compress::Bzip2](https://metacpan.org/pod/Compress::Bzip2)
- [Compress::Raw::Bzip2](https://metacpan.org/pod/Compress::Raw::Bzip2)
- [IO::Compress::Bzip2](https://metacpan.org/pod/IO::Compress::Bzip2)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
