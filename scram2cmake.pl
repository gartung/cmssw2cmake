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
my $proj_cmake="${base}/src/cmssw-cmake";
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
}
if ( -e "${base}/config/toolbox/${arch}/tools/selected/coral.xml")
{
  my $coral=`scram tool tag coral CORAL_BASE`; chomp $coral;
  my $ver=$coral; $ver=~s/.*\///;
  print "Generating Coral $ver ....\n";
  system("cd $coral ; pwd; eval `scram runtime -sh` >/dev/null 2>&1; ${THIS_SCRIPT} coral ${proj_cmake}/coral");
}
my $cc=&Cache::CacheUtilities::read($prods);
my %data=();
foreach my $dir (keys %{$cc->{BUILDTREE}})
{
  if (-e "${base}/${idir}/CMakeLists.txt") {system("rm -f ${base}/src/$dir/CMakeLists.txt");}
  if (! exists $cc->{BUILDTREE}{$dir}{METABF}) {next;}
  if (scalar(@{$cc->{BUILDTREE}{$dir}{METABF}})==0){next;}
  my $cmdir=dirname($cc->{BUILDTREE}{$dir}{METABF}[0]);
  my $class = $cc->{BUILDTREE}{$dir}{CLASS};
  %data=();
  system("rm -f ${base}/$cmdir/CMakeLists.txt");
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
    if (-e "${base}/${idir}/CMakeLists.txt") {system("rm -f ${base}/${idir}/CMakeLists.txt");}
    system("echo \"include($name.cmake)\" \>\>${base}/$cmdir/CMakeLists.txt");
  }
  elsif(($class eq "PACKAGE") && (exists $cc->{BUILDTREE}{$dir}{RAWDATA}{content}))
  {
    $name=$dir; $name=~s/\///;
    my $c=$cc->{BUILDTREE}{$dir}{RAWDATA}{content};
    my @deps=();
    push @deps,&dump_deps($c);
    my $idir="${cmdir}/interface";
    system("rm -f ${base}/$cmdir/*.cmake");
    if (scalar(@deps)>0)
    {
      my $r;
      my $class="INTERFACE";
      my $ss="*.h";
      &dump_contents($class,"interface",$cmdir, $name, $ss,$c);
      print($r, "include($name.cmake)\n");
      if (-e "${base}/${idir}")
      {
        &dump_cmake_module($name, $idir, "interface", \@deps);
        if (-e "${base}/${idir}/CMakeLists.txt") {system("rm -f ${base}/${idir}/CMakeLists.txt");}
        system("echo \"include(${name}.cmake)\" \>\> ${base}/${idir}/CMakeLists.txt"); 
      }
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
      if((-e "${cmdir}/classes.h") && (-e "${cmdir}/classes_def.xml"))
      {
        $data{rootdict}=[];
        push @{$data{rootdict}},["classes.h","classes_def.xml"];
      }
      foreach my $l (keys %{$c->{$t}})
      {
        my $files="*.cxx";
        if (! exists $c->{$t}{$l}{FILES}){$files="";}
        if(scalar(@{$c->{$t}{$l}{FILES}})>0){$files=join(" ",@{$c->{$t}{$l}{FILES}});}
        if ($files ne "")
        {
          if ($t eq "LIBRARY" ) {&dump_contents($class,"library",$cmdir, $l, $files,$c1, $c->{$t}{$l}{content});
                                 system("echo \"include($l.cmake)\" \>\>${base}/$cmdir/CMakeLists.txt");}
          if ($t eq "BIN"     ) {&dump_contents($class,"binary",$cmdir, $l, $files,$c1, $c->{$t}{$l}{content});
                                 system("echo include\"($l.cmake)\" \>\>${base}/$cmdir/CMakeLists.txt");}
          if ($class eq "TEST") {&dump_contents($class,"testbin",$cmdir, $l, $files,$c1, $c->{$t}{$l}{content});
                                 system("echo include\"($l.cmake)\" \>\>${base}/$cmdir/CMakeLists.txt");}
        }
      }
    }
  }
  #system("rm -f ${base}/$cmdir/CMakeLists.txt");
  #my @cmks = glob("${base}/$cmdir/*.cmake");
  #foreach my $cm (@cmks){
  #  system("cat $cm >> ${base}/$cmdir/CMakeLists.txt");
  #}
}
if ($proj ne ""){exit(0);}
system("cp ${SCRIPT_DIR}/cmake/CMakeLists.txt.tmp ${base}/src/CMakeLists.txt");
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

sub dump_external_project()
{
  my $dir=shift;
  my $name=shift;
  my $cont1=shift;
  my $cont2=shift || undef;
  if ($name eq ""){print "######## $dir: No name\n";return;}
  print "Processing external project for $name\n";
  my $m;

  open($m,">${dir}/${name}.cmake");
    print $m "file(MAKE_DIRECTORY \"tmp/${dir}\")\n";
    print $m "file(MAKE_DIRECTORY \"${dir}\")\n";
    print $m "\n";
    print $m "ExternalProject_add(${name}\n";
    print $m "  TMP_DIR \"tmp/${dir}\"\n";
    print $m "  STAMP_DIR \"tmp/${dir}/stamp\"\n";
    print $m "  DOWNLOAD_DIR \"tmp/${dir}\"\n";
    print $m "  SOURCE_DIR \"${base}/${dir}\"\n";
    print $m "  BINARY_DIR \"${dir}\"\n";
    print $m "  INSTALL_DIR \"${base}\"\n";
    print $m "  CMAKE_COMMAND \"cmake\"\n";
    print $m "  CMAKE_GENERATOR \"Unix Makefiles\"\n";
    print $m "  CMAKE_ARGS \"-DCMAKE_INSTALL_PREFIX:PATH=${base}\"\n";
    print $m "  BUILD_COMMAND \"make\"\n";
    print $m "  BUILD_ALWAYS TRUE\n";
    print $m "  DEPENDS \n";

    my @deps=();
    if (defined $cont1){push @deps,&dump_deps($cont1); push @flags,&dump_comp_flags($cont1);}
    if (defined $cont2){push @deps,&dump_deps($cont2); push @flags,&dump_comp_flags($cont2);}
    if (scalar(@deps))
    {
      foreach my $d (@deps)
      { 
        my $u = $d;
        if ($u =~ /\//) {
        $u =~ s/\///;
        $u =~ s/^\s+|\s+$//g;
        print $m "    $u\n";}
      }
    }
    print $m "\n  )\n\n";
  close($m);
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
  if ($files eq "" and not ($dir eq "interface") ){print "######## $dir: No Files\n";return;}
  print "Processing target $name\n";
  my $r; 
    if($type eq "interface")
      {
      open($r,">${dir}/interface/${name}.cmake");
      }
    else
      {
      open($r,">${dir}/${name}.cmake");
      }

  if (($type eq "library") || ($type eq "interface"))
  { 
    my @deps=();
    my @flags=();
    if (defined $cont1){push @deps,&dump_deps($cont1); push @flags,&dump_comp_flags($cont1);}
    if (defined $cont2){push @deps,&dump_deps($cont2); push @flags,&dump_comp_flags($cont2);}
    if ($type eq "interface")
    {
      print $r "add_library(${name} INTERFACE)\n";
      print $r "include_directories(${name}  \${CMAKE_SOURCE_DIR})\n";
      print $r "include_directories(${name}  \${CMAKE_INSTALL_PREFIX}/include)\n";
    }
    else
    { 
      print $r "file(GLOB PRODUCT_SOURCES $files)\n";
      print $r "if(PRODUCT_SOURCES)\n";
      print $r "\tadd_library(${name} SHARED \${PRODUCT_SOURCES})\n";
      print $r "\tinstall(TARGETS ${name}  DESTINATION lib)\n";
      print $r "\tinclude_directories(${name}  \${CMAKE_SOURCE_DIR})\n";
      print $r "\tinclude_directories(${name} \${CMAKE_INSTALL_PREFIX}/include)\n";
      print $r "endif()\n\n";
    }
    if ($class eq "PLUGIN") 
    {
      print $r "SET_TARGET_PROPERTIES(${name} PROPERTIES PREFIX \"plugin\")\n";
      print $r "edmplugingen(${name})\n\n";
    }
    if (scalar(@deps))
    {
      foreach my $d (@deps)
      { 
        my $u = $d;
        $u =~ s/\///;
        $u =~ s/^\s+|\s+$//g;
        print $r "cms_find_package(${u})\n";
        #if ($d =~ /\//) { print $r "add_dependencies(${name} ${u})\n";}
      }
      print $r "\n";
    }
    print $r "if(_LIBS)\n";
    print $r "\tlink_libraries(${name} \${LIB_TYPE} \${_LIBS})\n";
    print $r "\tunset(_LIBS)\n";
    print $r "endif()\n\n";
    print $r "cms_find_package(gcc-cxxcompiler)\n";
    print $r "cms_find_package(gcc-ccompiler)\n";
    print $r "cms_find_package(gcc-f77compiler)\n\n";
    if (scalar(@flags)>0)
    {
     print $r "compile_options(${name} ",join(" ",@flags),")\n\n";
    }
    if (exists $data{rootdict})
    {
      foreach my $x (@{$data{rootdict}})
      {
        print $r "add_rootdict_rules(${name})\n";
        print $r "cms_rootdict(${name} $x->[0] $x->[1])\n\n";
      }
    }
    if(($class ne "TEST") || ($class ne "BIN")) {&dump_cmake_module($name, $dir, $type, \@deps)};
  }
  if ($type eq "binary")
  {
    my @deps=();
    my @flags=();
    if (defined $cont1){push @deps,&dump_deps($cont1); push @flags,&dump_comp_flags($cont1);}
    if (defined $cont2){push @deps,&dump_deps($cont2); push @flags,&dump_comp_flags($cont2);}
    print $r "file(GLOB PRODUCT_SOURCES $files)\n";
    print $r "add_executable(${name} \${PRODUCT_SOURCES})\n";
    print $r "include_directories(${name}  \${CMAKE_SOURCE_DIR})\n";
    print $r "include_directories(${name} \${CMAKE_INSTALL_PREFIX}/include)\n";
    if (scalar(@deps))
    {
      foreach my $d (@deps)
      {
        my $u = $d;
        $u =~ s/CLHEP/clhep/;
        $u =~ s/\///;
        $u =~ s/^\s+|\s+$//g;
        print $r "cms_find_package(${u})\n";
      }
    }
    if (scalar(@flags)>0)
    {
     print $r "compile_options(${name} ",join(" ",@flags),")\n";
    }
    print $r "install(TARGETS ${name}  DESTINATION bin)\n";
  }
  if ($type eq "testbin")
  {
    my @deps=();
    if (defined $cont1){push @deps,&dump_deps($cont1);}
    my @trargs=();
    my @pretest=();
    if (defined $cont2)
    {
        if(exists $cont2->{FLAGS}{TEST_RUNNER_ARGS}) 
            {
              push @trargs, $cont2->{FLAGS}{TEST_RUNNER_ARGS};
            }
        if(exists $cont2->{FLAGS}{PRE_TEST}) 
            {
              push @pretest, $cont2->{FLAGS}{PRE_TEST};
            }
    
    }
    print $r "cms_add_test(${name}_CTest "; 
    print $r "COMMAND ${name} \n";
    if (scalar(@trargs)>0)
    {
        print $r "\t\t\tTRARGS\n";
        foreach my $a (@trargs)
        {
        if ($a) {print $r "\t\t\t\t$a->[0]\n";}
        }
    } 
        print $r "\t\t\t)\n";
    if (scalar(@pretest)>0)
    {
        foreach my $p (@pretest)
        {
        if ($p) {print $r "set_tests_properties( ${name}_CTest PROPERTIES DEPENDS $p->[0]_CTest)\n";}
        }
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

  if ($proj eq "coral")
  {$mkfile=~s/^lcg_//;}
  my $r;
  open($r,">${proj_modules}/Find${mkfile}.cmake");
  print $r "if(NOT ${mkfile}_FOUND)\n";
  print $r "\tset(${mkfile}_FOUND TRUE)\n";
  if($proj eq "coral")
  {
    my $d = "coral";
    print $r "\tlink_libraries(${name})\n";
    print $r "\tcms_find_package(${d})\n";
  }
  else 
  {
    print $r "\tlink_libraries(${name})\n";
  }
  foreach my $d (@$deps)
  {
      $d =~ s/\///;
      $d =~ s/^\s+|\s+$//g;
      $d=~s/^LCG//;
      $d=~s/-/_/g;
    print $r "\tcms_find_package(${d})\n";
  }
  print $r "endif()\n";
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
    if($x eq "CLHEP"){$x="clhep";}
    my $u=$x;
    $u=~s/-/_/g;
    if (-e "${tools}/Find${u}.cmake"){push @deps,$u;}
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


