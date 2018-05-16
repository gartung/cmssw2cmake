#!/usr/bin/env perl
use FindBin;
use File::Basename;
use Cwd 'abs_path';
my $THIS_SCRIPT=abs_path($0);
my $SCRIPT_DIR=${FindBin::Bin};
use lib "$FindBin::Bin/src";
use Cache::CacheUtilities;
my $relbase=$ENV{CMSSW_RELEASE_BASE};
my $base=$ENV{CMSSW_BASE} || ".";
my $arch=$ENV{SCRAM_ARCH};
my $proj=shift || "";
my $proj_cmake="${base}/cmssw-cmake";
my $proj_modules=shift || "${proj_cmake}/cmssw";
my $tools="${proj_cmake}/tools";
my $prods="${base}/.SCRAM/${arch}/ProjectCache.db.gz";
chdir($base);
system("rm -rf $proj_modules $tools; mkdir -p $proj_modules");
if ($proj eq "")
{
  print "Generating tools...\n";
  system("${SCRIPT_DIR}/tools2cmake.pl $tools");
  system("${SCRIPT_DIR}/runtime2cmake.pl $proj_modules");
  my $coral=`scram tool tag coral CORAL_BASE`; chomp $coral;
  my $ver=$coral; $ver=~s/.*\///;
  print "Generating Coral $ver ....\n";
  system("cd $coral ; pwd; eval `scram runtime -sh` >/dev/null 2>&1; ${THIS_SCRIPT} coral ${proj_cmake}/coral");
}
my $cc=&Cache::CacheUtilities::read($prods);
my %data=();
foreach my $dir (keys %{$cc->{BUILDTREE}})
{
  system("rm -f ${base}/src/$dir/CMakeLists.txt");
  if (! exists $cc->{BUILDTREE}{$dir}{METABF}) {next;}
  if (scalar(@{$cc->{BUILDTREE}{$dir}{METABF}})==0){next;}
  my $cmdir=dirname($cc->{BUILDTREE}{$dir}{METABF}[0]);
  my $class = $cc->{BUILDTREE}{$dir}{CLASS};
  %data=();
  if ($class eq "LIBRARY")
  {
    if (-d "${cmdir}/src"){$cmdir="${cmdir}/src";}
    system("rm -f ${base}/$cmdir/*.cmake");
    my $name=$cc->{BUILDTREE}{$dir}{NAME};
    my $c=$cc->{BUILDTREE}{$dir}{RAWDATA}{content};
    if ((exists $c->{FLAGS}) && (exists  $c->{FLAGS}{LCG_DICT_HEADER}))
    {
      my $x=$c->{FLAGS};
      if (exists $x->{LCG_DICT_HEADER})
      {
        my @h=split(" ",$x->{LCG_DICT_HEADER}[0]);
        my @xml=split (" ",$x->{LCG_DICT_XML}[0]);
        my $l=scalar(@h);
        $data{rootdict}=[];
        for(my $i=0;$i<$l;$i++)
        {
          push @{$data{rootdict}},[$h[$i], $xml[$i]];
        }
      }
    }
    elsif((-e "${cmdir}/classes.h") && (-e "${cmdir}/classes_def.xml"))
    {
      $data{rootdict}=[];
      push @{$data{rootdict}},["classes.h","classes_def.xml"];
    }
    my $ss="*.cc *.cxx *.f *.f77";
    if ((exists $c->{FLAGS}) && (exists  $c->{FLAGS}{ADD_SUBDIR})){$ss="*.cc *.cxx *.f *.f77 */*.cc */*.cxx */*.f */*.f77"}
    &dump_contents($class,"library",$cmdir, $name, $ss,$c);
  }
  elsif(($class eq "PACKAGE") && (exists $cc->{BUILDTREE}{$dir}{RAWDATA}{content}))
  {
    $name=$dir; $name=~s/\///;
    my @deps=();
    push @deps,&dump_deps($cc->{BUILDTREE}{$dir}{RAWDATA}{content});
    system("rm -f ${base}/$cmdir/*.cmake");
    if (scalar(@deps)>0)
    {
      my $r;
      my $type="INTERFACE";
      open($r,">${base}/${cmdir}/${name}.cmake");
      print $r "  cms_add_interface($name $type ",join(" ",@deps),")\n";
      close($r);
      &dump_cmake_module($name, $dir, $type, \@deps);
    }
  }
  elsif(($class eq "PLUGINS") || ($class eq "TEST") || ($class eq "BINARY"))
  {
    system("rm -f ${base}/$cmdir/*.cmake");
    my $c1=$cc->{BUILDTREE}{$dir}{RAWDATA}{content};
    my $c=$c1->{BUILDPRODUCTS};
    my @tt=("LIBRARY","BIN");
    foreach my $t (@tt)
    {
      if (! exists $c->{$t}){next;}
      foreach my $l (keys %{$c->{$t}})
      {
        my $files="*.cc";
        if (! exists $c->{$t}{$l}{FILES}){$files="";}
        if(scalar(@{$c->{$t}{$l}{FILES}})>0){$files=join(" ",@{$c->{$t}{$l}{FILES}});}
        if ($t eq "LIBRARY"){&dump_contents($class,"library",$cmdir, $l, $files,$c1, $c->{$t}{$l}{content});}
        if (($t eq "BIN") && ($files ne "")){&dump_contents($class,"binary",$cmdir, $l, $files,$c1, $c->{$t}{$l}{content});}
        if (($class eq "TEST") && ($t eq "BIN") && ($files ne "")){&dump_contents($class,"testbin",$cmdir, $l, $files,$c1, $c->{$t}{$l}{content});}
      }
    }
  }
  system("rm -f ${base}/$cmdir/CMakeLists.txt");
  my @cmks = glob("${base}/$cmdir/*.cmake");
  foreach my $cm (@cmks){
    system("cat $cm >> ${base}/$cmdir/CMakeLists.txt");
  }
}
if ($proj ne ""){exit(0);}
system("cp ${SCRIPT_DIR}/cmake/CMakeLists.txt ${base}/src/CMakeLists.txt");
if (! -e "${proj_cmake}/cmake"){system("cp -r ${SCRIPT_DIR}/cmake ${proj_cmake}/cmake");}
my @xdirs=("bin","test","plugins","src");
foreach my $d (glob("${base}/src/*"))
{
  if(-f $d){next;}
  if (-d $d)
  {
    if (! -f "${d}/CMakeLists.txt")
    {
      system("echo 'get_filename_component(CMS_SUBSYSTEM_NAME \${CMAKE_CURRENT_SOURCE_DIR} NAME)' > ${d}/CMakeLists.txt");
      system("echo 'process_subdirs()' >> ${d}/CMakeLists.txt");
    }
    foreach my $s (glob("${d}/*"))
    {
      if(-f $s){next;}
      my $xdir="";
      foreach my $x (@xdirs){if (-e "$s/$x"){$xdir="$x $xdir";}}
      if ($xdir ne "")
      {
        system("echo 'get_filename_component(CMS_PACKAGE_NAME \${CMAKE_CURRENT_SOURCE_DIR} NAME)' >> ${s}/CMakeLists.txt");
        system("echo 'process_subdirs($xdir)' >> ${s}/CMakeLists.txt");
      }
    }
  }
}

sub dump_contents()
{
  my $class=shift;
  my $type=shift;
  my $dir=shift;
  my $name=shift;
  my $files=shift;
  my $cont1=shift;
  my $cont2=shift || undef;
  if ($name eq ""){print "######## $dir: No name\n";return;}
  if ($files eq ""){print "######## $dir: No Files\n";return;}
  print "Processing $name\n";
  my $r; my $m;
  if ($type eq "testbin")
  {
  open($r,">${dir}/zz_${name}.cmake");
  }
  else
  {
  open($r,">${dir}/${name}.cmake");
  }
  if ($type eq "library")
  { 
    if (exists $data{rootdict})
    {
      foreach my $x (@{$data{rootdict}})
      {
        print $r "  cms_rootdict(${name} $x->[0] $x->[1])\n";
      }
    }
    my @deps=();
    my @flags=();
    if (defined $cont1){push @deps,&dump_deps($cont1); push @flags,&dump_comp_flags($cont1);}
    if (defined $cont2){push @deps,&dump_deps($cont2); push @flags,&dump_comp_flags($cont2);}
    print $r "cms_add_library(${name}\n";
    print $r "                TYPE ${class}\n";
    print $r "                SOURCES\n";
    print $r "                  $files\n";
    if (scalar(@deps))
    {
      print $r "                PUBLIC\n";
      foreach my $u (@deps)
      {
        print $r "                  $u\n";
      }
    }
    print $r "                )\n";
    if (scalar(@flags)>0)
    {
     print $r "target_compile_options($name PRIVATE ",join(" ",@flags),")\n";
    }
  &dump_cmake_module($name, $dir, $type, \@deps);
  }
  if ($type eq "binary")
  {
    my @deps=();
    my @flags=();
    if (defined $cont1){push @deps,&dump_deps($cont1); push @flags,&dump_comp_flags($cont1);}
    if (defined $cont2){push @deps,&dump_deps($cont2); push @flags,&dump_comp_flags($cont2);}
    print $r "cms_add_binary(${name}\n";
    print $r "                TYPE ${class}\n";
    print $r "                SOURCES\n";
    print $r "                  $files\n";
    if (scalar(@deps))
    {
      print $r "                PUBLIC\n";
      foreach my $u (@deps)
      {
        print $r "                  $u\n";
      }
    }
    print $r "                )\n";
    if (scalar(@flags)>0)
    {
     print $r "target_compile_options($name PRIVATE ",join(" ",@flags),")\n";
    }
  &dump_cmake_module($name, $dir, $type, \@deps);
  }
  if ($type eq "testbin")
  {
    my @deps=();
    if (defined $cont1){push @deps,&dump_deps($cont1);}
    my @args=();
    if (defined $cont2){push @args,&dump_ctest_args($cont2);}
    my $tname="";
    if (scalar(@args)>2)
    {
      shift @args;
      my $cmd = shift @args;
      my $wdir = shift @args;
      while (@args)
      {   
          my $c = shift @args;
          print $r "cms_add_test(${name}_${c}\n"; 
          print $r "             \$\{CMAKE_CURRENT_SOURCE_DIR\}/${c}\n";
          print $r "                DEPS\n";
          if (scalar(@deps))
          {
            foreach my $dep (@deps)
            {
             print $r "               ${dep}\n"
            }
          }
          print $r "             )\n";
      }
    }
    else
    {
          print $r "cms_add_test(${name}_CTest\n";
          print $r "             ${name} \n";
          if (scalar(@deps))
          {
            print $r "          DEPS\n";
            foreach my $dep (@deps)
            {
             print $r "               ${dep}\n"
            }
          }
          print $r "             )\n";
    }
  }
  close($r);
}

sub dump_cmake_module()
{
  my $name=shift;
  my $dir=shift;
  my $type=shift;
  my $deps=shift;
  my $mkfile=$name;
  if ($proj eq "coral"){$mkfile=~s/^lcg_//;}
  my $r;
  open($r,">${proj_modules}/Find${mkfile}.cmake");
  print $r "set(${mkfile}_FOUND TRUE)\n";
  print $r "mark_as_advanced(${mkfile}_FOUND)\n";
  foreach my $d (@$deps)
  {
    if ($proj eq "coral"){$d=~s/^LCG\///;}
    print $r "cms_find_package($d)\n";
  }
  if($proj eq "coral")
  {
    print $r "cms_find_package(CORAL)\n";
    print $r "cms_find_library($mkfile $name)\n";
  }
  if ($type ne "INTERFACE")
  {
    print $r "set(LIBRARY_DIRS \$<TARGET_FILE_DIR:${name}> \${LIBRARY_DIRS})\n";
    print $r "set(PATH \$<TARGET_FILE_DIR:${name}>  \${PATH})\n";
  }
  close($r);
}

sub dump_deps()
{
  my $cont=shift;
  my @deps=();
  foreach my $x (@{$cont->{USE}})
  {
    if(! defined $x){next;}
    if($x eq "f77compiler"){$x="gcc-f77compiler";}
    my $u=$x;
    my $uc=uc($x); $uc=~s/-/_/g;
    if (-e "${tools}/Find${uc}.cmake"){push @deps,$uc;}
    else{unshift @deps,$x;}
  }
  foreach my $x (@{$cont->{LIB}})
  {
    if(! defined $x){next;}
    push @deps,$x;
  }
  return @deps;
}

sub dump_comp_flags()
{
  my $c=shift;
  my @flags=();
  if (exists $c->{FLAGS})
  {
    my @fs = ("CPPDEFINES", "CPPFLAGS", "CXXFLAGS");
    foreach my $f (@fs)
    {
      if(exists $c->{FLAGS}{$f})
      {
        my $ch="";
        if ($f eq "CPPDEFINES"){$ch="-D";}
        foreach my $v (@{$c->{FLAGS}{$f}}){push @flags,"${ch}${v}";}
      }
    }
  }
  return @flags;
}

sub dump_ctest_args()
{
  my $c=shift;
  my @args=();
  my @fs = ("TEST_RUNNER_ARGS");
  foreach my $f (@fs)
  {
    if(exists $c->{FLAGS}{$f})
    {
      foreach my $v (@{$c->{FLAGS}{$f}})
        {
          foreach my $f (split(/ /, $v)) 
            {
            push @args, "${f}";
            }
        }
    }
  }
  return @args
}
