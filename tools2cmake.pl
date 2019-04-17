#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/src";
use Cache::CacheUtilities;
my $base=$ENV{CMSSW_BASE};
my $arch=$ENV{SCRAM_ARCH};
my $prods="${base}/.SCRAM/${arch}/ToolCache.db.gz";
chdir($base);
my $cc=&Cache::CacheUtilities::read($prods);
my $tools = shift || "${base}/cmssw-cmake/tools";
system("mkdir -p $tools");
my %data=();
foreach my $tool (keys %{$cc->{SETUP}})
{
  my $tus = $tool;
  $tus=~s/-/_/g;
  my $uc=uc($tool);
  $uc=~s/-/_/g;
  
  my $r;
  open($r,">${tools}/Find${tus}.cmake"); 
  print $r "if(NOT ${tus}_FOUND)\n";
  print $r "\tmark_as_advanced(${tus}_FOUND ${uc}_ROOT)\n";
  print $r "\tset(${tus}_FOUND TRUE)\n";
  my $base="";
  if (exists $cc->{SETUP}{$tool}{"${uc}_BASE"})
  {
    $base=$cc->{SETUP}{$tool}{"${uc}_BASE"};
    print $r "\tset(${uc}_ROOT \${CMAKE_INSTALL_PREFIX})\n";
  }
  if (exists $cc->{SETUP}{$tool}{USE})
  {
    foreach my $d (@{$cc->{SETUP}{$tool}{USE}})
    {
      if (exists $cc->{SETUP}{$d})
      {
         $d=~s/-/_/g;
         print $r "\tcms_find_package($d)\n";
      }
    }
  }
  if ($cc->{SETUP}{$tool}{INCLUDE})
  {
    foreach my $d (@{$cc->{SETUP}{$tool}{INCLUDE}})
    {
      if (-e $d)
      {
        if($base){$d=~s!$base(.*)!\${CMAKE_INSTALL_PREFIX}${1}!;}
        print $r "if(\${CMS_TARGET_NAME})\n";
        print $r "\ttarget_include_directories(\${CMS_TARGET_NAME} PUBLIC ${d})\n";
        print $r "endif()\n";
      }
    }
  }
  if ($cc->{SETUP}{$tool}{LIBDIR})
  {
    foreach my $d (@{$cc->{SETUP}{$tool}{LIBDIR}})
    {
      if (-e $d)
      {
        if($base){$d=~s/$base\//\${${uc}_ROOT}\//;}
        print $r "if(\${CMS_TARGET_NAME})\n";
        print $r "\ttarget_link_directories(\${CMS_TARGET_NAME} PUBLIC \${CMAKE_INSTALL_PREFIX}/lib)\n";
        print $r "endif()\n";
      }
    }
  }
  if ($cc->{SETUP}{$tool}{LIB})
  {
    foreach my $lib (@{$cc->{SETUP}{$tool}{LIB}})
    {
      if ($lib ne "")
      {
        print $r "if(\${CMS_TARGET_NAME})\n";
        print $r "\ttarget_link_libraries(\${CMS_TARGET_NAME} PUBLIC ${lib})\n";
        print $r "endif()\n";
      }
    }
  }
  if ($cc->{SETUP}{$tool}{FLAGS})
  {
    foreach my $f (keys %{$cc->{SETUP}{$tool}{FLAGS}})
    {
      if($f eq "CPPDEFINES")
      {
        print $r "if(\${CMS_TARGET_NAME})\n";
        foreach my $def (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "\ttarget_compile_defintions(\${CMS_TARGET_NAME} PUBLIC ${def})\n";}
        print $r "endif()\n";
      }
      elsif(($f eq "CPPFLAGS") || ($f eq "CXXFLAGS"))
      {
        print $r "if(\${CMS_TARGET_NAME})\n";
        foreach my $opt (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "\ttarget_compile_options(\${CMS_TARGET_NAME} PUBLIC ${opt})\n";}
        print $r "endif()\n";
      }
      elsif($f eq "CFLAGS")
      {
        print $r "if(\${CMS_TARGET_NAME})\n";
        foreach my $opt (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "\ttarget_compile_options(\${CMS_TARGET_NAME} PUBLIC ${opt})\n";}
        print $r "endif()\n";
      }
      elsif($f eq "FFLAGS")
      {
        print $r "if(\${CMS_TARGET_NAME})\n";
        foreach my $opt (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "\ttarget_compile_options( \${CMS_TARGET_NAME} PUBLIC ${opt})\n";}
        print $r "endif()\n";
      }
      else
      {
        print $r "if(\${CMS_TARGET_NAME})\n";
        foreach my $v (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {
          if ($f eq "REM_CXXFLAGS")
          {
            print $r "\tlist(FIND PROJECT_CXXFLAGS $v ${v}_FOUND)\n";
            print $r "\tif(${v}_FOUND)\n";
            print $r "\t\tlist(REMOVE_ITEM PROJECT_CXXFLAGS $v)\n";
            print $r "\tendif()\n"; 
          }
        }
        print $r "endif()\n";
      }
    }
    print $r "if(\${CMS_TARGET_NAME})\n";
    print $r "\tif(PROJECT_CXXFLAGS)\n";
    print $r "\t\ttarget_compile_options(\${CMS_TARGET_NAME} PUBLIC \${PROJECT_CXXFLAGS})\n";
    print $r "\t\tunset(PROJECT_CXXFLAGS)\n";
    print $r "\tendif()\n";
    print $r "\tif(PROJECT_CPPDEFINES)\n";
    print $r "\t\ttarget_compile_definitions(\${CMS_TARGET_NAME} PUBLIC \${PROJECT_CPPDEFINES})\n";
    print $r "\t\tunset(PROJECT_CPPDEFINES)\n";
    print $r "\tendif()\n";
    print $r "endif()\n";
  }
  print $r "endif()\n";
  close($r);
}

