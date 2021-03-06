#!/usr/bin/perl

use Env;
use DBI;

use lib "scripts";

require image_sharing;

sub usage_and_die()
{
  my $x = 
  "Parameters: AE Host Port Folder Count [ID Name AccessionNumber]";

  print "$x\n";
  exit();
}

sub p {
 my ($path, $name, $patientID, $accessionNumber) = @_;

# print "$path\n";
 %h = image_sharing::extract_DICOM_attributes($path);
 my $studyUID         = $h{"0020 000D"};
 my $fName            = $h{"0010 0010"};
 my $fPatientID       = $h{"0010 0020"};
 my $fAccessionNumber = $h{"0008 0050"};
# print "$path  $studyUID\n";
 my $pass = 1;
 if ($fName ne $name) {
  print "Name in file <$fName> does not match expected <$name>\n";
  $pass = 0;
 }
 if ($fPatientID ne $patientID) {
  print "PID in file <$fPatientID> does not match expected <$patientID>\n";
  $pass = 0;
 }
 if ($fAccessionNumber ne $accessionNumber) {
  print "Acession Number in file <$fPatientID> does not match expected <$patientID>\n";
  $pass = 0;
 }
 return $pass;
}

sub extract {
 my $path = shift;
 %h = image_sharing::extract_DICOM_attributes($path);
 my @rtn;

 my $index = 0;
 while ($a = shift) {
  $rtn[$index] = $h{$a};
#  print "$rtn[$index]\n";
  $index++;
 }
 return @rtn;
}

sub walk{
 %h = @_;

 foreach $e(keys %h) {
  $val = $h{$e};
  print "$e $val\n";
 }
 die "ZZ";
}

## Main starts here
 image_sharing::check_environment();
 ($ae, $dcmHost, $port) = image_sharing::default_DICOM_params();
 ($defaultEdgeFolder)   = image_sharing::default_EDGE_params();

 image_sharing::check_dicom_rcvr($ae, $dcmHost, $port);

 $folderDICOM = "/rsna/test-data/HitachiMR-2011-KIN";
 $targetFolder= "$defaultEdgeFolder/dcm/A-4001-03";
 image_sharing::remove_folder($targetFolder);

 ($name, $patID, $accessionNumber) = ("Waters^C", "A-4001-03", "A-4001-03-ACC");
 image_sharing::cstore($folderDICOM, $ae, $dcmHost, $port, $name, $patID, $accessionNumber, "");
 print "DICOM files transmitted\n";

 @allFiles = <$targetFolder/A-4001-03-ACC/*>;
 $totalFiles = scalar(@allFiles);
 $totalPass = 0;
 my %seriesReceivedHash;
 foreach $f(@allFiles) {
  $totalPass += p($f, $name, $patID, $accessionNumber);
  ($sopInstanceUID, $seriesInstanceUID) = extract($f, "0008 0018", "0020 000E");
  $seriesReceivedHash{$sopInstanceUID} = $seriesInstanceUID;
 }

 my %seriesSourceHash;
 @allFiles = <$folderDICOM/*/*>;

 foreach $f(@allFiles) {
  ($sopInstanceUID, $seriesInstanceUID) = extract($f, "0008 0018", "0020 000E");
  $seriesSourceHash{$sopInstanceUID} = $seriesInstanceUID;
 }

 $seriesUIDMatches = 0;
 foreach $e(keys %seriesSourceHash) {
  $valSource = $seriesSourceHash{$e};
  $valReceived = $seriesReceivedHash{$e};
  if ($valSource eq $valReceived) {
   $seriesUIDMatches++;
  } else {
   print "Series Instance UID does not match for this SOP Instance: $e\n";
  }
  
 }

  die "A-4001-03 fail: at least one file did not pass ($totalPass of $totalFiles did pass)\n" if ($totalPass != $totalFiles);
  die "A-4001-03 fail: expected 12 files, not $totalPass)\n" if ($totalPass != 12);
  die "A-4001-03 fail: expected 12 Series UID Matches, not $seriesUIDMatches)\n" if ($seriesUIDMatches != 12);

  
  print "A-4001-03 pass\n";
