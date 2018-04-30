#!/usr/bin/env perl
use File::Basename;
BEGIN{unshift @INC,"/cvmfs/cms.cern.ch/share/lcg/SCRAMV1/V2_2_7_pre9/src";}
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
  my $uc=uc($tool); $uc=~s/-/_/g;
  my $r;
  open($r,">${tools}/Find${uc}.cmake");
  print $r "  mark_as_advanced(${uc}_FOUND)\n";
  print $r "  set(${uc}_FOUND TRUE)\n";
  if (exists $cc->{SETUP}{$tool}{USE})
  {
    foreach my $d (@{$cc->{SETUP}{$tool}{USE}})
    {
      if (exists $cc->{SETUP}{$d})
      {
         $d=uc($d);
         $d=~s/-/_/g;
         print $r "  cms_find_package($d)\n";
      }
    }
  }
  my $base="";
  if (exists $cc->{SETUP}{$tool}{"${uc}_BASE"})
  {
    $base=$cc->{SETUP}{$tool}{"${uc}_BASE"};
    print $r "  set(${uc}_ROOT $base)\n";
  }
  if ($cc->{SETUP}{$tool}{INCLUDE})
  {
    foreach my $d (@{$cc->{SETUP}{$tool}{INCLUDE}})
    {
      if (-e $d)
      {
        if($base){$d=~s/$base\//\${${uc}_ROOT}\//;}
        print $r "  set(INCLUDE_DIRS $d \${INCLUDE_DIRS})\n";
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
        print $r "  set(LIBRARY_DIR $d \${LIBRARY_DIR})\n";
      }
    }
  }
  if ($cc->{SETUP}{$tool}{LIB})
  {
    my $libs = join(" ",reverse @{$cc->{SETUP}{$tool}{LIB}});
    if ($libs ne ""){print $r "  cms_find_library(${uc} ${libs})\n";}
  }
  if ($cc->{SETUP}{$tool}{FLAGS})
  {
    foreach my $f (keys %{$cc->{SETUP}{$tool}{FLAGS}})
    {
      if($f eq "CPPDEFINES")
      {
        foreach my $def (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "  set(PROJECT_${f} \${PROJECT_${f}} -D${def})\n";}
      }
      elsif(($f eq "CPPFLAGS") || ($f eq "CXXFLAGS"))
      {
        foreach my $opt (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "  set(PROJECT_${f} \${PROJECT_${f}} ${opt})\n";}
      }
      elsif($f eq "CFLAGS")
      {
        foreach my $opt (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "  set(PROJECT_${f} \"\${PROJECT_${f}} ${opt}\")\n";}
        print $r "  set(CMAKE_C_FLAGS \"\${CMAKE_C_FLAGS} \${PROJECT_${f}}\")\n";
      }
      elsif($f eq "FFLAGS")
      {
        foreach my $opt (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "  set(PROJECT_${f} \"\${PROJECT_${f}} ${opt}\")\n";}
        print $r "  set(CMAKE_F_FLAGS \"\${CMAKE_F_FLAGS} \${PROJECT_${f}}\")\n";
      }
      else
      {
        foreach my $v (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {
          if ($f eq "REM_CXXFLAGS")
          {
            print $r "  string(REPLACE \"$v\" \"\" PROJECT_CXXFLAGS \"\${PROJECT_CXXFLAGS}\")\n";
          }
        }
      }
    }
  }
  close($r);
}

