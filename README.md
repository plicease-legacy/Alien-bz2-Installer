# Alien::bz2::Installer

Installer for bz2

# CLASS METHODS

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

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
