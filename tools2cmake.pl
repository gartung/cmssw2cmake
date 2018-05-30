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
system("rm -r $tools; mkdir -p $tools");
my %data=();
foreach my $tool (keys %{$cc->{SETUP}})
{
  my $uc=uc($tool);
  $uc=~s/-/_/g;
  
  my $r;
  open($r,">${tools}/Find${uc}.cmake");
  my @vars = ("_INCLUDE_DIRS", "_LIBRARY_DIRS", "_LIBS", "_CPPDEFINES", "_CXXFLAGS", "_CFLAGS", "_FFLAGS");
  print $r "  mark_as_advanced(${uc}_FOUND ${uc}_ROOT ";
  foreach my $v (@vars)
  { 
    print $r "${uc}${v} ";
  } 
  print $r ")\n";
  print $r "  set(${uc}_FOUND TRUE)\n";
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
        print $r "  list(APPEND ${uc}_INCLUDE_DIRS \"$d\")\n";
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
        print $r "  list(APPEND ${uc}_LIBRARY_DIRS \"$d\")\n";
      }
    }
  }
  if ($cc->{SETUP}{$tool}{LIB})
  {
    foreach my $lib (@{$cc->{SETUP}{$tool}{LIB}})
    {
      if ($lib ne "")
      {
        print $r "  list(APPEND ${uc}_LIBS ${lib})\n";
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
        {print $r "  list(APPEND ${uc}_PROJECT_${f} -D${def})\n";}
      }
      elsif(($f eq "CPPFLAGS") || ($f eq "CXXFLAGS"))
      {
        foreach my $opt (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "  list(APPEND ${uc}_PROJECT_${f} ${opt})\n";}
      }
      elsif($f eq "CFLAGS")
      {
        foreach my $opt (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "  list(APPEND ${uc}_PROJECT_${f} \"${opt}\")\n";}
        print $r "  list(APPEND ${uc}_CMAKE_C_FLAGS \"${uc}_\${PROJECT_${f}}\")\n";
      }
      elsif($f eq "FFLAGS")
      {
        foreach my $opt (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {print $r "  list(APPEND ${uc}_PROJECT_${f} \"${opt}\")\n";}
        print $r "  list(APPEND ${uc}_CMAKE_F_FLAGS \"${tool}_\${PROJECT_${f}}\")\n";
      }
      else
      {
        foreach my $v (@{$cc->{SETUP}{$tool}{FLAGS}{$f}})
        {
          if ($f eq "REM_CXXFLAGS")
          {
            print $r "  list(REMOVE_ITEM ${uc}_PROJECT_CXXFLAGS  \"$v\")\n";
          }
        }
      }
    }
  }
  if (exists $cc->{SETUP}{$tool}{USE})
  {
    foreach my $d (@{$cc->{SETUP}{$tool}{USE}})
    {
      if (exists $cc->{SETUP}{$d})
      {
         my $d = uc($d);
         $d=~s/-/_/g;
         print $r "  if(NOT ${d}_FOUND)\n";
         print $r "    cms_find_package(${d})\n";
         print $r "  endif()\n";
         foreach my $v (@vars)
         {
           print $r "  if(${d}${v})\n";
           print $r "    list(APPEND ${uc}${v} \${${d}${v}})\n";
           print $r "  endif()\n";
         }
     }
    }
    foreach my $v (@vars)
    {
      print $r "  if(${uc}${v})\n";
      print $r "  list(REMOVE_DUPLICATES ${uc}${v})\n";
      print $r "  endif()\n";
    }
  }
  close($r);
}

