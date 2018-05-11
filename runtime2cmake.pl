#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/src";
use Cache::CacheUtilities;
my $base=$ENV{CMSSW_BASE};
my $arch=$ENV{SCRAM_ARCH};
my $prods="${base}/.SCRAM/${arch}/RuntimeCache.db.gz";
my $proj_cmake="${base}/cmssw-cmake";
my $proj_modules=shift || "${proj_cmake}/cmssw";
chdir($base);
my $cc=&Cache::CacheUtilities::read($prods);

open($r,">${proj_modules}/FindRuntime.cmake");

foreach my $pvar (keys %{$cc->{path}})
{
  my $value="";
  my $c1=$cc->{path}{$pvar};
  foreach $v (@$c1)
  {
    if ($v){ if ($value eq "") {$value=$v;} else {$value=$value.":".$v;} }
  }
  print $r "set(RUNTIME \"$pvar=$value\" \${RUNTIME})\n";
}

foreach my $h (@{$cc->{variables}})
{
  while (my ($var,$val) = each %$h)
  {
    print $r "set(RUNTIME \"$var=$val->[0]\" \${RUNTIME})\n";
  }
}

close($r);
