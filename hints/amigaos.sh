# hints/amigaos.sh
#
# talk to pueschel@imsdd.meb.uni-bonn.de if you want to change this file.
#
# misc stuff
archname='m68k-amigaos'
cc='gcc'
firstmakefile='GNUmakefile'
usenm='true'

usedl='n'
usemymalloc='n'
usevfork='true'
useperlio='true'
d_eofnblk='define'
d_fork='undef'
d_vfork='define'
groupstype='int'

# libs

libpth="$prefix/lib /local/lib"
glibpth="$libpth"
xlibpth="$libpth"

libswanted='gdbm m'
so=' '

# compiler & linker flags

ccflags='-DAMIGAOS -mstackextend'
ldflags=''
optimize='-O2 -fomit-frame-pointer'

# uncomment the following settings if you are compiling for an 68020+ system

# ccflags='-DAMIGAOS -mstackextend -m68020 -resident32'
# ldflags='-m68020 -resident32'

# uncomment the following line if you want dynamic loading and
# a working version of dld is available

# usedl=''
# ccflags='-DAMIGAOS -mstackextend'
# ldflags=''
# optimize='-O2 -fomit-frame-pointer'
# dlext='o'
# cccdlflags='none'
# ccdlflags='none'
# lddlflags='-oformat a.out-amiga -r'

# When AmigaOS runs a script with "#!", it sets argv[0] to the script name.
toke_cflags='ccflags="$ccflags -DARG_ZERO_IS_SCRIPT"'

# Avoid telldir prototype conflict in pp_sys.c  (AmigaOS uses const DIR *)
# Configure should test for this.  Volunteers?
pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'

# AmigaOS always reports only two links to directories, even if they
# contain subdirectories.  Consequently, we use this variable to stop
# File::Find using the link count to determine whether there are
# subdirectories to be searched.  This will generate a harmless message:
# Hmm...You had some extra variables I don't know about...I'll try to keep 'em.
#	Propagating recommended variable dont_use_nlink
dont_use_nlink='define'
