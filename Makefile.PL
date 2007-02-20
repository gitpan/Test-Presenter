use ExtUtils::MakeMaker;
use File::Basename;
use File::Spec::Functions qw|:ALL|;
use Config;
use strict;

my %args = (
            pkg_name  => 'Test-Presenter',
            name      => 'Test-Presenter',
            DESTDIR   => undef
            );

# Grab out any custom cmdline args
my @pass_args;
while (my $arg = shift @ARGV) {
    my ($key, $value) = split /=/, $arg;
    if (exists $args{$key}) {
        $args{$key} = $value;
    } else {
        push @pass_args, $arg;
    }
}
@ARGV = @pass_args;

my %opts = (
            'NAME'          => "$args{'name'}",
            'AUTHOR'        => "John Daiker <daikerjohn\@gmail.com>",
            'ABSTRACT_FROM' => "lib/Test/Presenter.pm",
            'VERSION_FROM'  => "lib/Test/Presenter.pm",
            'EXE_FILES'     => [ qw( scripts/treport
                                     scripts/test_report_example
                               ) ],
            'PREREQ_PM'     => {
                'Pod::Usage'       => 0,
                'Getopt::Long'     => 0,
                'IO::File'         => 0,
                'Sleepycat::DbXml' => 0,
                'Template'         => 0,
                'Chart::Graph::Gnuplot' => 0,
                'SVG::TT::Graph' => 0,
            },
);

WriteMakefile( %opts );

sub install_clause {
    my ($source, $target_dir, $overwrite) = @_;
    $overwrite = 1 unless (defined($overwrite));

    my $text = '';

    $text .= "install :: $source\n";
    $text .= "\t\$(MKPATH) $target_dir\n";
    $text .= "\t\$(CHMOD) a+rx $target_dir\n";
    if ($source) {
        if (-d $source) {
            # If we're copying a directory, update all permissions of subdirs & files
            $text .= "\tfind $source -type d | xargs \$(CHMOD) a+rx\n";
            $text .= "\tfind $source -type f | xargs \$(CHMOD) a+r\n";
        }
        if ($overwrite) {
            # Copy everything recursively excluding CVS dirs and preserving permissions
            $text .= "\t\$(RSYNC) -Cpr $source $target_dir\n";
        }
        elsif (-f $source) {
            # Don't over-write
            # (This assumes we're installing a _file_, not a directory tree)
            my $dest_file = catfile( $target_dir, basename( $source ) );
            $text .= "\tif [ -f $dest_file ]; ";
            $text .= "then \$(CP) $source $dest_file.dist; ";
            $text .= "else \$(CP) $source $dest_file; fi\n";
            $text .= "\t\$(CHMOD) -R a+r $dest_file\n";
        }
        else {
            die "Can't install directory '$source' unless overwrite=1\n";
        }
    }
#    $text .= "\n";
    return $text;
}

sub MY::postamble {
    my $self = shift;
    my $text = '';
    my $templatedir = '';

    $text .= "RSYNC = rsync\n";
    $text .= "CHOWN = chown\n\n";

    # Determine location of etc conf files
    my $destdir = $args{DESTDIR} || '/usr/share';

    my $templatedir   = catdir( $destdir, $args{pkg_name}, 'templates' );
    my $templatefiles = catfile( 'tm', "*.tmpl" );
  
    $text .= install_clause($templatefiles, $templatedir, 1);

    return $text;
}


# vi:set ai ts=4 sw=4 expandtab:
