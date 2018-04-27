#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(strftime);
use File::Copy;
use Carp;

our $VERSION = '0.0.07';    # version of this script

#  Minerva is an Athena seris api export xml file or tabbed list parser
#  takes file name as the only argument, checks if it has tabs

# requires file name as argument
my $fin = shift @ARGV || 'None';

# @ARGV undef  || 'None' makes it never undef

# root dir name
my $root = 'minerva9';

# output file is same as $fin but _date.txt
my $fout;

# ID and series variables & counters
my $ID;
my $series;
my $IDcount = 0;
my $scount  = 0;
my $xcount  = 0;
my $tcount = 0; # Text title count for tabbed lists

# array to hold series titles
my @series_titles;

# date stamp when run to use as file name suffix
my $date_stamp = strftime( '%H%M%S_%d-%m-%Y', localtime );

# delimited XML substitution
sub fixXML {
    my $parm = $_[0];
    $parm =~ s/&amp;/&/g;
    $parm =~ s/&gt;/>/g;
    $parm =~ s/&lt;/</g;
    $parm =~ s/&quot;/"/g;
    $parm =~ s/&apos;/'/g;
    $parm =~ s/&#xA;/\n/g;
    $parm =~ s/&#xa;/\n/g;
    $parm =~ s/&#xD;/\r/g;
    $parm =~ s/&#xd;/\r/g;
    $parm =~ s/&#x9;/\t/g;
    return ($parm);
}

# welcome message
print "\n  Welcome to the Minerva parser, $VERSION, $date_stamp\n";

# Sanity check the input file

if ( $fin =~ /None/xsm ) {
    print " Athena requires a file name or you will have no olives\n";
    exit 0;
}
if ( $fin =~ /.txt$/xsm ) {

    if ( -f $fin ) {
        print "  Athena will try and convert $fin for you ... \n\n";
    }
    else {
        print "  Athena cannot find that file ...\n";
        exit 0;
    }
}
else { print "  Athena requires a .txt file ...\n"; }

# create output file name from $fin
$fout = $fin;
$fout =~ s/.txt//xms;
$fout = $fout . '_' . $date_stamp . '.txt';

# check first line of file
open( my $CHECK, '<', $fin ) or croak "$fout would not open";
my $line = <$CHECK>;
close $CHECK;
print " First line is: $line\n";

my $selected =
  0;    # variable defining seleceted elements used for directory names
my $select1 =
  0;    # check concurrent series are different, select1 is the currentl line
my $select2 = 0;    # previous series line

# open file and begin parsing to new file
open( my $OFILE, '>', $fout ) or croak "$fout would not open";
open( my $AFILE, '<', $fin )  or croak "$fin would not open";

my @seriesline;     # array to hold line elements, including the series titles

# If first line has tabs, it probably not XML
if ( $line =~ m/\t/xsm ) {
    print " Thats got tabs!\n";
    while (<$AFILE>) {

    # remove line breaks, alternative to $/ = "\r\n"; for both Linux and Windows
        my $next = $_;
        $next =~ s/\r?\n//;

        # split on tab
        @seriesline = split( /\t/, $next );

        # check there are no undefined fields

        foreach my $check_undef (@seriesline) {
            if ( !defined $check_undef ) {
                print "  Undefined value found in @seriesline\n";

            }
        }

        # each line/array should have the same number of elements
        # unless there was a new line in the data value, so check
        my $cells         = @seriesline;
        my $allowed_cells = 8;
        if ( $cells ne $allowed_cells ) {
            print
              " Abort!! Allowed cells = $allowed_cells, cells found = $cells\n";
            print " @seriesline\n is in error\n";
            exit 0;
        }
        # Some debug:
        # print "  Line cell count = $cells\n";
        # print all lines
        # print " @seriesline\n";
        # print just the desired items
        # print "  @seriesline[3] -@seriesline[4]\n";
        # if ( !defined $seriesline[4] ){
        #  print " undefined value found in @seriesline\n";
        # exit 0;
        # }
        $select1 = "$seriesline[4] -$seriesline[3]";

        if ( $select1 eq $select2 ) {

            # print " $selecct1 is a duplicate!";
            # so ignore this
        }
        else {
            $select2 = "$seriesline[4] -$seriesline[3]";

            # select2 is only created if previous selection is not the same
           # Print all deduplicated lines
           # print " $select2\n";
            push @series_titles, $select2;
            $tcount ++;
        }
    }

    # remove header i.e. first line, as this would end up creating a directory
    my $header = shift @series_titles;
    print "  Header of tabbed list is: $header\n";

    print " Last line is: @seriesline\n";
    print " TEXT SUMMARY:\n Title count is $tcount\n";
}
else {
   #  Assume its not a tab delimited list and it has XML tags in there somewhare
    while (<$AFILE>) {
        if ( $_ =~ m/<seriesID>(\d+)<\/seriesID>/xsm ) {
            $ID = $1;

            # print "$1\n";
            $IDcount++;
        }
        if ( $_ =~ m/<series>(.*)<\/series>/xsm ) {
            $series = $1;
            $scount++;

         # if series title contains xml delimited values, substitute ASCII value
            if ( $series =~ m/&(.+);/xsm ) {
                my @matches;

                # fixed $series
                my $fixed = $series;
                @matches = $series =~ /(&.+;)/gsm;
                foreach my $match (@matches) {

                    my $fix = fixXML($match);

                    # print "xml chars: $match, fixed with $fix\n";
                    $fixed =~ s/$match/$fix/gms;
                    $xcount++;
                }

                # print "\n $series\n is now\n $fixed\n";
                $series = $fixed;
            }

            # create new string with ID added to fixed series name
            my $seriesWithID = "$series -$ID\n";

            # print "$seriesWithID";
            print $OFILE $seriesWithID;
            push @series_titles, $seriesWithID;
        }
    }
}    # end of else its not a tabbed file
close $AFILE or carp "  could not close $fin";
close $OFILE or carp "  could not close $fin";

# create a root directory to hold a directory structure
unless ( -d "$root" ) {
    mkdir "$root";
}

foreach (@series_titles) {
    my $title = $_;

    # print "$_";
    # translate non windows dir chars
    $title =~ tr/:/-/;
    $title =~ tr/\\/-/;
    $title =~ tr/\//-/;
    $title =~ tr/?/-/;
    $title =~ tr/|/-/;

    # Some titles are quoted so they begin with some form of quote mark
    # this would become the parent directory so all quotes have been removed

    $title =~ s/"//g;

    # As apostrophe is also used as a quote mark these will also be removed

    $title =~ s/'//g;

    # Some titles begin with a leading space, so remove all starting spaces

    $title =~ s/^\s+//g;
    $title =~ s/^-+//g;

    # WINDOWS-1252 CP1252 8-bit character encoding

#<80> Euro becomes E
#<E9> e with accent becomes e
#<C9> E with accent becomes E
#<91> opening single quote becomes '
#<92> closing single quote becomes '
#<93> open double quote becomes '
#<94> close double quote becomes '
#<95> bullet point becomes .
#<96> CP1252 hyphen small becomes -
#<97> CP1252 hyphen large becomes -
# But if title is empty the next character needs to be used after replacement TODO CHECK THIS IS NOT EMPTY
    $title =~ s/[\x91\x92\x93\x94]//g;
    $title =~ s/[\x95]/\./g;
    $title =~ s/[\x96\x97]/-/g;
    $title =~ s/[\x80]/Euro /g;    
    $title =~ s/[\xC9]/E/g; # E with ascending accent
    $title =~ s/[\xE9]/e/g;

    # print every title line, enable for debug
    # print "$title\n";

    # take first char, convert to uppper case, create dir base on this
    my $first = substr $title, 0, 1;
    $first =~ tr/a-z/A-Z/;

    if ( $first =~ tr/\x20-\x7f//cd ) {
        print "  Title $title begins with a strange character  \n";
        exit 0;
    }
    $first = $root . '/' . $first;

    # create first char directory
    # print "$first\n";
    unless ( -d "$first" ) {
        mkdir $first;
    }

    # chomp cleaned series_title and create series directories
    my $chompd = $title;
    chomp $chompd;
    my $subdir = $first . '/' . $chompd;
    
    # define any default child directories here:
    my @subs = ( 'Audio Stems', 'HD ProRes', 'MXF XDCAM HD', 'XML' );

    # create series_subdirectory/default_children
    # print "$subdir\n";
    unless ( -d "$subdir" ) {
        mkdir "$subdir";
    }

        foreach  (@subs) {
        my $child = $subdir . '/' . $_;
        # print " child dir will be $child \n";
             unless ( -d "$child" ) {
             mkdir "$child";
             } 
        }
    # Name of temporary xml 
    my $tempxml = 'temp.xml';
    # Add path to name (must be an exising sub) 
    $tempxml = "$subdir" .'/XML/' . "$tempxml";
    # print " opening $tempxml\n";
      open( my $XML, '>', $tempxml ) or croak "$tempxml would not open";
      close ( $XML) or croak "$tempxml would not open";

     
}
print
"\n\n  XML SUMMARY:\n  IDcount = $IDcount\n  Series Count = $scount\n  Corrected XML delimited Chars = $xcount\n  Ouptput file = $fout\n\n";
exit 0;

__END__

This script uses a file seriesID_and_series_only.txt previously created from the export

grep "<series*" text.txt > seriesID_and_series_only.txt

grep -P '<series>' text.txt > series_only.txt

uniq -D series_only.txt
                    <series>Body Beautiful</series>
                    <series>Body Beautiful</series>

Then zip the created directory
zip -r minerva.zip minerva
