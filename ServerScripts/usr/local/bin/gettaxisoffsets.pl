#! /usr/bin/perl
{
use POSIX;

if ($#ARGV - $nopt <= -1)
{
 instructions();
 exit(0);
 } 
$inputfile=$ARGV[$#ARGV];
if ($inputfile =~ /orig\.HEAD/){
$file = $outputfile = $inputfile;
$outputfile =~ s/\+orig\.HEAD//g;
$outputfile = $outputfile."_taxisoffsets.dat";
}else{
$file = $inputfile."+orig.HEAD";
$outputfile = $inputfile."_taxisoffsets.dat";
}

#$file = "bcaipi_spep_hcp_rest_revbrik+orig.HEAD";
open (F, $file) || die ("Could not open $file!");
open(MYOUTFILE, ">$outputfile")|| die ("Could not open $file!"); #open for write

while ($line = <F>)
{
chomp($line);

if ($line =~ /TAXIS_OFFSETS/)
{
#print $line."\n";
$line = <F>;
chomp($line);
#print $line."\n";
($junk,$inumber) = split '=', $line;
$inumber = int($inumber);
$flines = $inumber / 5;
$mod = $inumber % 5;

$flines = int($flines);
#print "iNumber ".$inumber."\n";
#print "Full Lines ".$flines."\n";
#print "mod=" . $mod, "\n";

$j = 1;

for ($i = 1; $i <= $flines; $i++) {
	$line = <F>;
	chomp($line);
#	print $line."\n";
	($i1,$i2,$i3,$i4,$i5) = split ' ', $line;
	$myarray[$j++] = $i1;
	$myarray[$j++] = $i2;
	$myarray[$j++] = $i3;
	$myarray[$j++] = $i4;
	$myarray[$j++] = $i5;
	
}



if ($mod>0){
	$line = <F>;
	chomp($line);
#	print $line."\n";
	@temp = split ' ', $line;
	for ($k = 0; $k <= $mod; $k++) {
	$myarray[$j++] = $temp[$k];
	}

}




}



}
for ($k = 1; $k <= $inumber; $k++) {
	#print $k." ".$myarray[$k]."\n";
	print MYOUTFILE $myarray[$k]."\n";
	}

sub instructions {
  print "\nThis program will extract the TAXIS_OFFSETS from a HEAD file in to a file with the same name as the input.\n";
  print "Usage: gettaxisoffsets.pl input\n";
  print "       [options]\n";
  print "       <input name>\n";

  print "Example:  gettaxisoffsets.pl bcaipi_spep_hcp_rest_revbrik\n";
  print "Please email problems to eghobrial@ucsd.edu";
  exit(0);
  }	
	
}
