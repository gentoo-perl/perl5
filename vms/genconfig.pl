#!/usr/bin/perl
# Habit . . .
#
# Extract info from Config.VMS, and add extra data here, to generate Config.sh
# Edit the static information after __END__ to reflect your site and options
# that went into your perl binary.  In addition, values which change from run
# to run may be supplied on the command line as key=val pairs.
#
# Rev. 16-Feb-1998  Charles Bailey  bailey@newman.upenn.edu
#

#==== Locations of installed Perl components
$prefix='perl_root';
$builddir="$prefix:[000000]";
$installbin="$prefix:[000000]";
$installscript="$prefix:[000000]";
$installman1dir="$prefix:[man.man1]";
$installman3dir="$prefix:[man.man3]";
$installprivlib="$prefix:[lib]";
$installsitelib="$prefix:[lib.site_perl]";

unshift(@INC,'lib');  # In case someone didn't define Perl_Root
                      # before the build

if ($ARGV[0] eq '-f') {
  open(ARGS,$ARGV[1]) or die "Can't read data from $ARGV[1]: $!\n";
  @ARGV = ();
  while (<ARGS>) {
    chomp;
    push(@ARGV,split(/\|/,$_));
  }
  close ARGS;
}

if (-f "config.vms") { $infile = "config.vms"; $outdir = "[-]"; }
elsif (-f "[.vms]config.vms") { $infile = "[.vms]config.vms"; $outdir = "[]"; }
elsif (-f "config.h") { $infile = "config.h"; $outdir = "[]";}

if ($infile) { print "Generating Config.sh from $infile . . .\n"; }
else { die <<EndOfGasp;
Can't find config.vms or config.h to read!
	Please run this script from the perl source directory or
	the VMS subdirectory in the distribution.
EndOfGasp
}
$outdir = '';
open(IN,"$infile") || die "Can't open $infile: $!\n";
open(OUT,">${outdir}Config.sh") || die "Can't open ${outdir}Config.sh: $!\n";

$time = localtime;
$cf_by = (getpwuid($<))[0];
$archsufx = `Write Sys\$Output F\$GetSyi("HW_MODEL")` > 1024 ? 'AXP' : 'VAX';
($vers = $]) =~ tr/./_/;
$installarchlib = VMS::Filespec::vmspath($installprivlib);
$installarchlib =~ s#\]#.VMS_$archsufx.$vers\]#;
$installsitearch = VMS::Filespec::vmspath($installsitelib);
$installsitearch =~ s#\]#.VMS_$archsufx\]#;
($osvers = `Write Sys\$Output F\$GetSyi("VERSION")`) =~ s/^V?(\S+)\s*\n?$/$1/;

print OUT <<EndOfIntro;
# This file generated by GenConfig.pl on a VMS system.
# Input obtained from:
#     $infile
#     $0
# Time: $time

package='perl5'
CONFIG='true'
cf_time='$time'
cf_by='$cf_by'
ccdlflags='undef'
cccdlflags='undef'
mab='undef'
libpth='/sys\$share /sys\$library'
ld='Link'
lddlflags='/Share'
ranlib='undef'
ar='undef'
eunicefix=':'
hint='none'
hintfile='undef'
useshrplib='define'
usemymalloc='n'
usevfork='true'
spitshell='write sys\$output '
dlsrc='dl_vms.c'
binexp='$installbin'
man1ext='rno'
man3ext='rno'
arch='VMS_$archsufx'
archname='VMS_$archsufx'
bincompat3='undef'
d_bincompat3='undef'
osvers='$osvers'
prefix='$prefix'
builddir='$builddir'
installbin='$installbin'
installscript='$installscript'
installman1dir='$installman1dir'
installman3dir='$installman3dir'
installprivlib='$installprivlib'
installarchlib='$installarchlib'
installsitelib='$installsitelib'
installsitearch='$installsitearch'
path_sep='|'
startperl='\$ perl 'f\$env("procedure")' 'p1' 'p2' 'p3' 'p4' 'p5' 'p6' 'p7' 'p8' !
\$ exit++ + ++\$status != 0 and \$exit = \$status = undef;'
EndOfIntro

foreach (@ARGV) {
  ($key,$val) = split('=',$_,2);
  if ($key eq 'cc') {  # Figure out which C compiler we're using
    my($cc,$ccflags) = split('/',$val,2);
    my($d_attr);
    $ccflags = "/$ccflags";
    if ($ccflags =~s!/DECC!!ig) { 
      $cc .= '/DECC';
      $cctype = 'decc';
      $d_attr = 'undef';
    }
    elsif ($ccflags =~s!/VAXC!!ig) {
      $cc .= '/VAXC';
      $cctype = 'vaxc';
      $d_attr = 'undef';
    }
    elsif (`$val/NoObject/NoList _nla0:/Version` =~ /GNU C version (\S+)/) {
      $cctype = 'gcc';
      $d_attr = 'define';
      print OUT "gccversion='$1'\n";
    }
    elsif ($archsufx eq 'VAX' &&
           # Check exit status too, in case message is turned off
           ( `$val/NoObject/NoList /prefix=all _nla0:` =~ /IVQUAL/ ||
              $? == 0x38240 )) {
      $cctype = 'vaxc';
      $d_attr = 'undef';
    }
    else {
      $cctype = 'decc';
      $d_attr = 'undef';
    }
    print OUT "vms_cc_type='$cctype'\n";
    print OUT "d_attribut='$d_attr'\n";
    print OUT "cc='$cc'\n";
    if ( ($cctype eq 'decc' and $archsufx eq 'VAX') || $cctype eq 'gcc') {
      # gcc and DECC for VAX requires filename in /object qualifier, so we
      # have to remove it here.  Alas, this means we lose the user's
      # object file suffix if it's not .obj.
      $ccflags =~ s#/obj(?:ect)?=[^/\s]+##i;
    }
    $debug = $optimize = '';
    while ( ($qual) = $ccflags =~ m|(/(No)?Deb[^/]*)|i ) {
      $debug = $qual;
      $ccflags =~ s/$qual//;
    }
    while ( ($qual) = $ccflags =~ m|(/(No)?Opt[^/]*)|i ) {
      $optimize = $qual;
      $ccflags =~ s/$qual//;
    }
    $usethreads = ($ccflags =~ m!/DEF[^/]+USE_THREADS!i and
                   $ccflags !~ m!/UND[^/]+USE_THREADS!i);
    print OUT "usethreads='",($usethreads ? 'define' : 'undef'),"'\n";;
    $optimize = "$debug$optimize";
    print OUT "ccflags='$ccflags'\n";
    print OUT "optimize='$optimize'\n";
    $dosock = ($ccflags =~ m!/DEF[^/]+VMS_DO_SOCKETS!i and
               $ccflags !~ m!/UND[^/]+VMS_DO_SOCKETS!i);
    print OUT "d_vms_do_sockets=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_socket=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_sockpair=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_gethent=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_sethent=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_select=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "i_netdb=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "i_niin=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "i_neterrno=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_gethbyname=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_gethbyaddr=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_getpbyname=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_getpbynumber=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_getsbyname=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "d_getsbyport=",$dosock ? "'define'\n" : "'undef'\n";
    print OUT "netdb_name_type=",$dosock ? "'char *'\n" : "'undef'\n";
    print OUT "netdb_host_type=",$dosock ? "'char *'\n" : "'undef'\n";
    print OUT "netdb_hlen_type=",$dosock ? "'int'\n" : "'undef'\n";

    if ($dosock and $cctype eq 'decc' and $ccflags =~ /DECCRTL_SOCKETS/) {
      print OUT "selecttype='fd_set'\n";
      print OUT "d_getnbyaddr='define'\n";
      print OUT "d_getnbyname='define'\n";
      print OUT "netdb_net_type='long'\n";
    }
    else {
      print OUT "selecttype='int'\n";
      print OUT "d_getnybname='undef'\n";
      print OUT "d_getnybaddr='undef'\n";
      print OUT "netdb_net_type='undef'\n";
    }

    if ($cctype eq 'decc') {
      $rtlhas  = 'define';
      print OUT "useposix='true'\n";
      ($ccver,$vmsver) = `$cc/VERSION` =~ /V(\S+) on .*V(\S+)$/;
      # Best guess; the may be wrong on systems which have separately
      # installed the new CRTL.
      if ($ccver >= 5.2 and $vmsver >= 7) { $rtlnew = 'define'; }
      else                                { $rtlnew = 'undef';  }
    }
    else { $rtlhas = $rtlnew = 'undef';  print OUT "useposix='false'\n"; }
    foreach (qw[ d_stdstdio d_stdio_ptr_lval d_stdio_cnt_lval d_stdiobase
                 d_locconv d_setlocale i_locale d_mbstowcs d_mbtowc
                 d_wcstombs d_wctomb d_mblen d_mktime d_strcoll d_strxfrm ]) {
      print OUT "$_='$rtlhas'\n";
    }
    foreach (qw[ d_gettimeod d_uname d_truncate d_wait4 d_index
                 d_pathconf d_fpathconf d_sysconf d_sigsetjmp ]) {
      print OUT "$_='$rtlnew'\n";
    }
    next;
  }
  elsif ($key eq 'exe_ext') { 
    my($nodot) = $val;
    $nodot =~ s!\.!!;
    print OUT "so='$nodot'\ndlext='$nodot'\n";
  }
  elsif ($key eq 'obj_ext') { print OUT "dlobj='dl_vms$val'\n";     }
  print OUT "$key='$val'\n";
}

# Are there any other logicals which TCP/IP stacks use for the host name?
$myname = $ENV{'ARPANET_HOST_NAME'}  || $ENV{'INTERNET_HOST_NAME'} ||
          $ENV{'MULTINET_HOST_NAME'} || $ENV{'UCX$INET_HOST'}      ||
          $ENV{'TCPWARE_DOMAINNAME'} || $ENV{'NEWS_ADDRESS'};
if (!$myname) {
  ($myname) = `hostname` =~ /^(\S+)/;
  if ($myname =~ /IVVERB/) {
    warn "Can't determine TCP/IP hostname" if $dosock;
    $myname = '';
  }
}
$myname = $ENV{'SYS$NODE'} unless $myname;
($myhostname,$mydomain) = split(/\./,$myname,2);
print OUT "myhostname='$myhostname'\n" if $myhostname;
if ($mydomain) {
  print OUT "mydomain='.$mydomain'\n";
  print OUT "perladmin='$cf_by\@$myhostname.$mydomain'\n";
  print OUT "cf_email='$cf_by\@$myhostname.$mydomain'\n";
}
else {
  print OUT "perladmin='$cf_by'\n";
  print OUT "cf_email='$cf_by'\n";
}
chomp($hwname = `Write Sys\$Output F\$GetSyi("HW_NAME")`);
$hwname = $archsufx if $hwname =~ /IVKEYW/;  # *really* old VMS version
print OUT "myuname='VMS $myname $osvers $hwname'\n";

# Before we read the C header file, find out what config.sh constants are
# equivalent to the C preprocessor macros
if (open(SH,"${outdir}config_h.SH")) {
  while (<SH>) {
    next unless m%^#(?!if).*\$%;
    s/^#//; s!(.*?)\s*/\*.*!$1!;
    my(@words) = split;
    $words[1] =~ s/\(.*//;  # Clip off args from macro
    # Did we use a shell variable for the preprocessor directive?
    if ($words[0] =~ m!^\$(\w+)!) { $pp_vars{$words[1]} = $1; }
    if (@words > 2) {  # We may also have a shell var in the value
      shift @words;              #  Discard preprocessor directive
      my($token) = shift @words; #  and keep constant name
      my($word);
      foreach $word (@words) {
        next unless $word =~ m!\$(\w+)!;
        $val_vars{$token} = $1;
        last;
      }
    }
  }
  close SH;
}
else { warn "Couldn't read ${outdir}config_h.SH: $!\n"; }
$pp_vars{UNLINK_ALL_VERSIONS} = 'd_unlink_all_versions';  # VMS_specific

# OK, now read the C header file, and retcon statements into config.sh
while (<IN>) {  # roll through the comment header in Config.VMS
  last if /config-start/;
}

while (<IN>) {
  chop;
  while (/\\\s*$/) {  # pick up contination lines
    my $line = $_;
    $line =~ s/\\\s*$//;
    $_ = <IN>;
    s/^\s*//;
    $_ = $line . $_;
  }              
  next unless my ($blocked,$un,$token,$val) =
                 m%^(\/\*)?\s*\#\s*(un)?def\w*\s+([A-Za-z0-9]\w+)\S*\s*(.*)%;
  if (/config-skip/) {
    delete $pp_vars{$token} if exists $pp_vars{$token};
    delete $val_vars{$token} if exists $val_vars{$token};
    next;
  }
  $val =~ s!\s*/\*.*!!; # strip off trailing comment
  my($had_val); # Maybe a macro with args that we just #undefd or commented
  if (!length($val) and $val_vars{$token} and ($un || $blocked)) {
    print OUT "$val_vars{$token}=''\n" unless exists $done{$val_vars{$token}};
    $done{$val_vars{$token}}++;
    delete $val_vars{$token};
    $had_val = 1;
  }
  $state = ($blocked || $un) ? 'undef' : 'define';
  if ($pp_vars{$token}) {
    print OUT "$pp_vars{$token}='$state'\n" unless exists $done{$pp_vars{$token}};
    $done{$pp_vars{$token}}++;
    delete $pp_vars{$token};
  }
  elsif (not length $val and not $had_val) {
    # Wups -- should have been shell var for C preprocessor directive
    warn "Constant $token not found in config_h.SH\n";
    $token = lc $token;
    $token = "d_$token" unless $token =~ /^i_/;
    print OUT "$token='$state'\n";
  }
  next unless length $val;
  $val =~ s/^"//; $val =~ s/"$//;               # remove end quotes
  $val =~ s/","/ /g;                            # make signal list look nice
  # Library directory; convert to VMS syntax
  $val = VMS::Filespec::vmspath($val) if ($token =~ /EXP$/);
  if ($val_vars{$token}) {
    print OUT "$val_vars{$token}='$val'\n" unless exists $done{$val_vars{$token}};
    if ($val_vars{$token} =~ s/exp$//) {
      print OUT "$val_vars{$token}='$val'\n" unless exists $done{$val_vars{$token}};;
    }
    $done{$val_vars{$token}}++;
    delete $val_vars{$token};
  }
  elsif (!$pp_vars{$token}) {  # Haven't seen it previously, either
    warn "Constant $token not found in config_h.SH (val=|$val|)\n";
    $token = lc $token;
    print OUT "$token='$val'\n";
    if ($token =~ s/exp$//) {print OUT "$token='$val'\n";}
  }
}
close IN;
# Special case -- preprocessor manifest "VMS" is defined automatically
# on VMS systems, but is also used erroneously by the Perl build process
# as the manifest for the obsolete variable $d_eunice.
print OUT "d_eunice='undef'\n";  delete $pp_vars{VMS};

# XXX temporary -- USE_THREADS is currently on CC command line
delete $pp_vars{'USE_THREADS'};

foreach (sort keys %pp_vars) {
  warn "Didn't see $_ in $infile\n";
}
foreach (sort keys %val_vars) {
  warn "Didn't see $_ in $infile(val)\n";
}

if (open(OPT,"${outdir}crtl.opt")) {
  while (<OPT>) {
    next unless m#/(sha|lib)#i;
    chomp;
    if (/crtl/i || /gcclib/i) { push(@crtls,$_); }
    else                      { push(@libs,$_);  }
  }
  close OPT;
  print OUT "libs='",join(' ',@libs),"'\n";
  push(@crtls,'(DECCRTL)') if $cctype eq 'decc';
  print OUT "libc='",join(' ',@crtls),"'\n";
}
else { warn "Can't read ${outdir}crtl.opt - skipping 'libs' & 'libc'"; }

if (open(PL,"${outdir}patchlevel.h")) {
  while (<PL>) {
    if    (/^#define PATCHLEVEL\s+(\S+)/) { print OUT "PATCHLEVEL='$1'\n"; }
    elsif (/^#define SUBVERSION\s+(\S+)/) { print OUT "SUBVERSION='$1'\n"; }
  }
  close PL;
}
else { warn "Can't read ${outdir}patchlevel.h - skipping 'PATCHLEVEL'"; }

# simple pager support for perldoc                                             
if    (`most not..file` =~ /IVVERB/) {
  $pager = 'more';
  if (`more nl:` =~ /IVVERB/) { $pager = 'type/page'; }
}
else { $pager = 'most'; }
print OUT "pager='$pager'\n";

close OUT;
