#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/src";
use Cache::CacheUtilities;
my $base=$ENV{CMSSW_BASE};
my $arch=$ENV{SCRAM_ARCH};
my $prods="${base}/.SCRAM/${arch}/ToolCache.db.gz";
chdir($base);
my $cc=&Cache::CacheUtilities::read($prods);
my $tools = shift || "${base}/cmssw-cmake/modules";
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
  print $r "if(NOT ${uc}_FOUND)\n";
  print $r "  mark_as_advanced(${uc}_FOUND)\n";
  print $r "  set(${uc}_FOUND TRUE)\n";
  if (exists $cc->{SETUP}{$tool}{USE})
  {
    foreach my $d (@{$cc->{SETUP}{$tool}{USE}})
    {
      if (exists $cc->{SETUP}{$d})
      {
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
        print $r "  list(APPEND INCLUDE_DIRS $d)\n";
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
        print $r "  list(APPEND LIBRARY_DIRS $d)\n";
      }
    }
  }
  if ($cc->{SETUP}{$tool}{LIB})
  {
    foreach my $lib (@{$cc->{SETUP}{$tool}{LIB}})
    {
      if ($lib ne "")
      {
        print $r "  list(APPEND LIBS ${lib})\n";
      }
    }
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
  print $r "endif()\n";
  close($r);
}

