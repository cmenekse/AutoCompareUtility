#!/usr/bin/perl
$|=1;
package perlPackage;
use Archive::Extract;
use warnings;
use strict;
use Cwd;
use File::Compare;
use Text::Diff;
#$Archive::Extract::DEBUG=1;
###################################
my $compiledCount=0;
my $mainDir =getcwd;
#my $vsBinDir = "C:/\"Program Files\"/\"Microsoft Visual Studio 11.0\"/VC/bin/";
my $vsBinDir = "C:/\"Program Files (x86)\"/\"Microsoft Visual Studio 11.0\"/VC/bin/";
my $batFile="vcvars32.bat";
my $correctProgramName = "correctProgram.exe";
my $compilationReportFile = "compilationReportFile.txt";
my $theVeryBigReportFile = "VeryBigReportFile.txt";
my $theVeryBigReportFileHandler;
my $numberOfTsts=0;
my $isCountedTstsOnce=0;
my $samplesFileHandler;
my $samplesFile = "rawStatistics.txt";
###################################

#Apply a pattern to a line, if it matches return the grouped part
sub getPatternFromLine
{
	my ($line,$pattern)=@_;
	
	if( $line=~m/$pattern/)
	{
		return $1
	}
	
	else
	{
		return "ERR"
	}
	
}
#Appends the matched part of the pattern to a line and append the grouped part
#to the array containing all groups from previous lines
sub createComparableStructureFromFile
{
	my($fileHandler , $parsedArray,$pattern) = @_;
	my $modifiedLine;
	while( my $line = <$fileHandler>)
	{
		if($line !~ /^\s+$/)
		{
			$modifiedLine=getPatternFromLine($line,$pattern);
			if($modifiedLine ne "ERR")
			{
			push(@$parsedArray,$modifiedLine);
			}
		}
		
	}
}
#returns 1 if after applying the pattern the files are same
sub filesAreSameWithPattern
{
	my ($file1,$correctFile,$pattern)=@_;
	my @file1Parsed;
	my @correctFileParsed;
	
	open my $fileHandler1, $file1 or die "Could not open $file1: $!";
	open my $correctFileHandler , $correctFile or die "Could not open $correctFile: $!";
	createComparableStructureFromFile($fileHandler1,\@file1Parsed,$pattern);
	createComparableStructureFromFile($correctFileHandler,\@correctFileParsed,$pattern);
	close $fileHandler1;
	close $correctFileHandler;
	my $size1 =scalar @file1Parsed;
	my $size2 =scalar @correctFileParsed;
	
	if($size1 != $size2)
	{
		print $theVeryBigReportFileHandler ( " \nISSUE: the size does not match Expected: ". $size2 ."(".join(", ", @correctFileParsed).  ") Got: ".$size1. "(".join(", ", @file1Parsed).")\n " );
		return 0;
	}
	else
	{
		for (my $i =0; $i<$size1;$i++)
		{
			if ($file1Parsed[$i] ne $correctFileParsed[$i])
			{
				print $theVeryBigReportFileHandler ( "\nISSUE: Expected : " .$correctFileParsed[$i] . " Got : " .$file1Parsed[$i]."\n");
				return 0;
			}
		}
		return 1;
	}
	
	
}
#extract a zip file to given directory
sub extractZipFile
{
	
	my ($zipFileName,$extractTo)=@_;
	my $zipToBeExtracted= Archive::Extract->new(archive=>$zipFileName);
	$zipToBeExtracted->extract(to=> $extractTo);
}
#Extracts all the zip files in the directory even the ones that are extracted in
#this method and also it actually does some other things other than extracting too
#TODO : Refactor
sub extractAllZipFilesInDirectory
{
	my ($directory,$mainSubmitDirectory)=@_;
	
	if( directoryContainsExtensionFiles($directory,"cpp")!= 1)
	{
		
		if($directory=~m/([A-Za-z]+),(.*?)\(.*/)
		{
			$mainSubmitDirectory=$directory;
		}
		my $i=0;
		my $dh;
		opendir $dh , $directory or die $!;
		while (my $file = readdir($dh)) 
		{
			if($file =~ m/.*\.zip$/)
			{
			   $file =~ m/(.*)\.zip$/;
			   my $extractTo = $1; 
			   extractZipFile($directory."/".$file,$directory."/".$extractTo);
			   my $newDirectory=$directory."/".$extractTo;
			   extractAllZipFilesInDirectory($newDirectory,$mainSubmitDirectory);
			    
			}
			elsif (-d $directory."/".$file)
			{
				
				if($file!~/^(\.)+$/)
				{
					my $newDirectory=$directory."/".$file;
					extractAllZipFilesInDirectory($newDirectory,$mainSubmitDirectory);
				}
			}
		}	
		 
	}
	#possibly contain .cpp files
	else
	{	
		
		my $dh;
		opendir $dh , $directory or die $!;
		while (my $file = readdir($dh)) 
		{
			if($file =~ m/(.+)\.cpp/)
			{
				
				my $filename =$1;
				my $fileIsCompiled= compileFile($file,$directory,$filename);
				print( "\nCOMPILED $compiledCount so far\n ");
				$compiledCount=$compiledCount+1;
				my $cTst=0;
				if($fileIsCompiled==1)
				{
					
					generateOutputs($directory,$filename.".exe",$mainDir);
					compareAll($filename,$directory,$mainDir,$mainSubmitDirectory,$cTst);
				}
				
			    
			}
		}	
	}
	
}
#Add quotes to avoid space related issues in windows command line
sub addQuote
{
	 my $str = shift(@_);
	 return '"'.$str.'"';
}
#Get the name from the folder name with pattern
sub getNameFromFolderName
{
	my $filename = shift(@_);
	if ($filename=~m/([A-Za-z]+),(.*?)\(.*/)
	{
		return  ($2. " ".$1);
	}
}

sub getDiff
{
	 my ($file1,$file2)=@_;
	 my $diffs = diff $file1 => $file2;
	 return $diffs;
}
#Finds the tst file related that is equal to the searched.
sub findTstFile
{
	my ($searchedTstNum,$inputDirectory) = @_;
	my $dh;
	my $currentTstNum="A";
    opendir $dh , $inputDirectory or die $!;
    while (my $file = readdir($dh)) 
	{
		if($file=~m/OUTPUT_.*([0-9]+)/)
		{
			 my $currentTstNum=$1;
			 if($currentTstNum==$searchedTstNum)
			 {
				return $file;
			 }
		}
	}
	return "NOT FOUND ";
}
#Compare all the cases for a given file with the correctFile
sub compareAll
{
	my ($filename,$directory,$inputDirectory,$mainSubmitDirectory,$cTst)=@_;
	my $dh;
	print $theVeryBigReportFileHandler( "______________|".getNameFromFolderName($mainSubmitDirectory)."| WITH: ". $filename .".cpp________________ \n\n");
    opendir $dh , $directory or die $!;
	open (my $fh, ">",$directory."/"."report.txt") or die $!;
    while (my $file = readdir($dh)) 
	{
		if($file=~m/OUTPUT_.*?([0-9]+).*/)
		{
			my $searchedTstNum = $1;
			my $tstFile=findTstFile($searchedTstNum,$inputDirectory);
			my $fullPath=$directory."/".$file;
			print $fh ( "CASE# " . $searchedTstNum ."\n");
			print $theVeryBigReportFileHandler( "CASE# " . $searchedTstNum ."\n");
			my $equality=areFilesEqual($fullPath,$inputDirectory."/".$tstFile);
			
			if($equality==1)
			{
				$cTst=$cTst+1;
				print $fh ( "CASE " . $searchedTstNum . ": IS OK \n");
				print $theVeryBigReportFileHandler( "CASE " . $searchedTstNum . ": IS OK \n");
				
				
			}
			else
			{
				print $fh ( "CASE " . $searchedTstNum . ": IS NOT OK \n");
				my $diff=getDiff($fullPath,$inputDirectory."/".$tstFile);
				print($fh ( $diff."\n"));
				print $theVeryBigReportFileHandler ( "CASE " . $searchedTstNum . ": IS NOT OK \n");
				print($theVeryBigReportFileHandler ( $diff."\n"));
			}
		}
	}
	print $theVeryBigReportFileHandler (" It is " . $cTst . "/ " .$numberOfTsts."\n");
	print $samplesFileHandler($cTst.",");
	
}
#To check whether the .cpp compiled successfully, could be improved
sub isCompiled
{
	 my $compilerOutput=shift(@_);
	 if ( $compilerOutput=~m/.*\/out.*\.exe/)
	 {
		return 1;
	 }
	 return 0;
}
#Compiles a file ,prints the report 
#TODO : $filename and $file does not seem to be ideal names for these variables
sub compileFile
{
	
	my ($file,$directory,$fileName)=@_;
	my $compiled=0;
	my $compilerCommand ="cl/EHsc ".addQuote($directory."/".$file);
	my $changeDirectoryCommand= "cd " .$vsBinDir;
	my $executeCommand = $changeDirectoryCommand."&&".$batFile."&&".$compilerCommand;
	my $moveCommand=$changeDirectoryCommand."&&"."move ".addQuote($fileName.".exe")." " .addQuote($directory);
	my $output = qx/$executeCommand/;
	print($output);
	open(my $fh, '>>', $compilationReportFile) or die $!;
	if(isCompiled($output)==0)
	{
		
		print $fh ($fileName. " NOT COMPILED"."\n");
		
	}
	else
	{
		print $fh ($fileName. " compiled"."\n");
		$compiled=1;
	}
	
	print("///COMPILE OUTPUT END\n");
	$output=qx/$moveCommand/;
	return $compiled;	
}
#Generates outputs of the executable by applying the input files
sub generateOutputs
{
	my ($directory,$executable,$inputDirectory)=@_;
	my $dh;
	opendir $dh , $mainDir or die $!;
	while (my $file = readdir($dh)) 
	{
		if($file =~ m/^(?!OUTPUT)(.*INPUT.*)(\..+)/)
		{
			if($isCountedTstsOnce==0)
			{
				$numberOfTsts=$numberOfTsts+1;
			}
			my $fileName = $1;
			my $extension= $2;
			my $fullFileName= $1.$2;
			$fileName=~m/.*([0-9]+)/;
			my $tstNo= $1;
			$executable=~m/(.*)\.exe/;
			my $reducedExecutable=$1;
			
			my $executeCommand;
			if( $directory eq $mainDir)
			{
				 $executeCommand=addQuote($directory."/".$executable."<".$inputDirectory."/".$fullFileName.">".$directory."/"."OUTPUT_".$tstNo."_".$reducedExecutable.".txt");
				 system($executeCommand)
			}
			else
			{
				#workaround needs improvement
				my $cdToThatDirectory="cd ".addQuote($directory);
				
				system($cdToThatDirectory."&&".addQuote($executable)."<".$inputDirectory."/".$fullFileName.">"."OUTPUT_".$tstNo."_".addQuote($reducedExecutable).".txt");
			}
			
			
		    
		}
	}
	$isCountedTstsOnce=1;
}
#Checks whether two files are equal we can compare with different ways here
sub areFilesEqual
{
	my ($file1,$file2) = @_;
	my $pattern= '.*?([-+]?[0-9]+(\.?|,?)[0-9]*)';
	#if (compare($file1,$file2) == 0)
	if(filesAreSameWithPattern($file1,$file2,$pattern) == 1)
	{
		return 1; 
	}
	else
	{
		
		return 0;
	}
}

sub executeWithInputFile
{
	my ($input,$directory) = @_;
	
}
sub directoryContainsExtensionFiles
{
	my ($directory,$extensionType)=@_;
	my $dh;
	opendir $dh , $directory or die $!;
	while (my $file = readdir($dh)) 
	{
		if($file =~ m/.*\.$extensionType/)
		{
			return 1;
		}
	}
	return 0;
}
#Parses the input file that is seperated by lines for each case. Inside a single line it is seperated with commas (like CSV)
#This method generates input files for each line hence each case
sub createInputFilesFromSingleInputFile
{
	my $filename = shift(@_);
	open my $inputFileHandler , $filename or die $!;
	my $currentTstIndex=1;
	while (my $line = <$inputFileHandler>)
	{
		open(my $outputFile, '>', "INPUT_TEST_CASE_".$currentTstIndex.".txt") or die $!;
		my @currentLine =split(',',$line);
		foreach my $singleInput(@currentLine)
		{
			if($singleInput=~m/-?[0-9]+/)
			{
				print $outputFile($singleInput."\r\n");
			}
		}
		
		$currentTstIndex=$currentTstIndex+1;
		close $outputFile;
	}

}

createInputFilesFromSingleInputFile("tstCases.txt");
generateOutputs($mainDir,$correctProgramName,$mainDir);
open( my $someHandler, '>', $compilationReportFile) or die $!;
close $someHandler;
open($theVeryBigReportFileHandler, '>', $theVeryBigReportFile) or die $!;
open($samplesFileHandler, '>', $samplesFile) or die $!;
extractAllZipFilesInDirectory($mainDir,"");




