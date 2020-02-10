#!/usr/bin/perl
use JSON::Parse ':all';
#                       \"restricted\": true,

if( @ARGV != 1 ){
	print "USAGE: $0 detailedFileList\n";
	exit;
}
chomp $ARGV[0];
if( -d "$ARGV[0]_log" ){
	print "WARNING: Directory $ARGV[0]\_log already exists!\n";
}else{
	`mkdir $ARGV[0]\_log`;
}

open( IN, "<./$ARGV[0]" ) || die( "Unable to open ./$ARGV[0]\n" );
open( OUTFAIL, ">./$ARGV[0].failed" );
while( <IN> ){
#===============================================================================#
# Read in the detailed file list information (Google spread sheet - "File") and #
# generate json file which will be submitted to 2TDREAM DB                      #
#===============================================================================#
	next if( $_ =~ /^\#/ );
	chomp $_;
	@data = split( /\t/, $_ );
#	for( $i = 0; $i < @data; $i++ ){
#		print $i, "\t", $data[ $i ], "\n";
#	}
	if( $data[2] =~ /(NO)\s*(FASTQ)/i ){	#if no fastq file exists
		print "$data[3] has no fastq file\n\n";
		next;
	}
	$file = $data[4]."/".$data[5];	#datafle location
	@tmp = split( /\:/, $data[2] );	#remove lab info
	$id = $tmp[1];
###	$upload = $tmp[1].".fastq.gz";	#set new name wihch makes more sense
	$upload = $tmp[1].".".$data[5];

	#===============================================#
	# Check if the file has been submitted already	#
	#===============================================#
	$doneSubmission = `grep -c $upload submitted.txt`;
	chomp $doneSubmission;
	if( $doneSubmission ){
		print "$upload has already been submitted to T2DREAM.  Skip\n";
		next;	#skip if the file has already submitted
	}

	if( ! -e "./gz/$upload" ){
		print "ln -s $file ./gz/$upload\n";
		`ln -s $file ./gz/$upload`;
	}else{
		`rm ./gz/$upload`;
		`ln -s $file ./gz/$upload`;
	}
	$size = `wc -c $file`; die unless $size =~ /(\d+)/; $size = $1;
	$md5 = `md5sum $file | awk '{ print \$1 }'`; chomp( $md5 );
	#print $file, "\n", $md5, "\n\n";
	$r = "";
	$pairend = "";
	if( $data[2] =~ /\_R\d+$/ ){	#if it's paired-ended
		$r = substr $data[2], -1;	#get pair end info
		$pairend = "\"paired_end\":\ \"".$r."\",";
	}
	$pair = ""; #die unless $data[11] =~ /single-ended/ || $data[11] =~ /paired-ended/;
	if( $data[11] =~ /paired-ended/ & $data[2] =~ /R2$/ ) {
		$pair = $data[2];
		$pair =~ s/R2$/R1/;
		$pair = "\"paired_with\":\ \"".$pair."\",";
	}
	open( OUT, ">./json.log" );
	if( $data[5] !~ /\.fastq\.gz$/ && $data[5] !~ /\.sra$/ && $data[5] !~ /\.fq\.gz$/  && $data[5] !~ /fastq.zip$/){	#if it's not fastq raw data
		print "processed data\n";
		print OUT "{
				\"aliases\": [ \"$data[2]\" ],
				\"dataset\": \"$data[6]\",";
		if( $data[3] !~ /^\s*$/ ){	#if there is replicate information
			print OUT "
				\"replicate\": \"$data[3]\" ,";
		}
		if( $data[21] !~ /^\s*$/ ){	#if there is derived_from information
			$data[21] =~ s/\s*//g;
			print OUT "
				\"derived_from\": [";
			if( $data[21] =~ /\;/ ){
				@derivedFiles = split( /\;/, $data[21] );
				$n = @derivedFiles;
				for( $i = 0; $i < $n; $i++ ){
					print OUT "
						\"\/files\/$derivedFiles[ $i ]\/\"";
					if( $i != ( $n - 1 ) ){
						print OUT ",";
					}
				}
			}else{
				print OUT "
					\"\/files\/$data[21]\/\" ";
			}
			print OUT "
				],";
		}
		if( $data[20] !~ /^\s*$/ ){	#if there is controlled_by information
			$data[20] =~ s/\s*//g;
			print OUT "
				\"controlled_by\": [";
			if( $data[20] =~ /\;/ ){
				@controlledFiles = split( /\;/, $data[20] );
				$n = @controlledFiles;
				for( $i = 0; $i < $n; $i++ ){
					print OUT "
						\"\/files\/$controlledFiles[ $i ]\/\"";
					if( $i != ( $n - 1 ) ){
						print OUT ",";
					}
				}
			}else{
				print OUT "
					\"\/files\/$data[20]\/\" ";
			}
			print OUT "
				],";
###			print OUT "
###				\"controlled_by\": [ \"$data[20]\" ],";
		}
		if( $data[9] !~ /^\s*$/ ){     #if there is mapped_read_length information
			print OUT "
				\"mapped_read_length\": $data[9],";
		}
		if( $data[13] !~ /^bed/ & $data[13] !~ /^bigBed/ & $data[13] !~ /^gff/ ){
			print OUT "
				\"file_format\": \"$data[13]\",
				\"file_size\": $size,
				\"md5sum\": \"$md5\",
				\"output_type\": \"$data[15]\",
				\"submitted_file_name\": \"gz/$upload\",
				\"lab\": \"$data[17]\",
				\"award\": \"$data[16]\",
				\"assembly\": \"$data[14]\"
			}";
		}else{
			@tmps = split( /\s+/, $data[13] );
			print OUT "
				\"file_format\": \"$tmps[0]\",
				\"file_format_type\": \"$tmps[1]\",
				\"file_size\": $size,
				\"md5sum\": \"$md5\",
				\"output_type\": \"$data[15]\",
				\"submitted_file_name\": \"gz/$upload\",
				\"lab\": \"$data[17]\",
				\"award\": \"$data[16]\",
				\"assembly\": \"$data[14]\"
			}";
		}
	}else{
		print OUT "{
			\"aliases\": [ \"$data[2]\" ],
			$pair
			\"dataset\": \"$data[6]\",
			\"replicate\": \"$data[3]\",";
		if( $data[21] !~ /^\s*$/ ){	#if there is derived_from information
			$data[21] =~ s/\s*//g;
			print OUT "
				\"derived_from\": [";
			if( $data[21] =~ /\;/ ){
				@derivedFiles =	split( /\;/, $data[21] );
				$n = @derivedFiles;
				for( $i	= 0; $i	< $n; $i++ ){
					print OUT "
						\"\/files\/$derivedFiles[ $i ]\/\"";
					if( $i != ( $n - 1 ) ){
						print OUT ",";
					}
				}
			}else{
				print OUT "
					\"\/files\/$data[21]\/\" ";
			}
			print OUT "
				],";
###			print OUT "
###				\"derived_from\": [ \"$data[21]\" ],";
		}
		if( $data[20] !~ /^\s*$/ ){	#if there is controlled_by information
			$data[20] =~ s/\s*//g;
			print OUT "
				\"controlled_by\": [";
			if( $data[20] =~ /\;/ ){
				@controlledFiles = split( /\;/, $data[20] );
				$n = @controlledFiles;
				for( $i = 0; $i < $n; $i++ ){
					print OUT "
						\"\/files\/$controlledFiles[ $i ]\/\"";
					if( $i != ( $n - 1 ) ){
						print OUT ","; 
					}
				}
			}else{
				print OUT "
					\"\/files\/$data[20]\/\" ";
			}
			print OUT "
				],";
###			print OUT "
###				\"controlled_by\": [ \"$data[20]\" ],";
		}
		if( $data[9] !~ /^\s*$/ ){     #if there is mapped_read_length information
			print OUT "
				\"mapped_read_length\": $data[9],";
		}
		print OUT "
			\"run_type\": \"$data[11]\",
			$pairend
			\"file_format\": \"$data[13]\",
			\"file_size\": $size,
			\"md5sum\": \"$md5\",
			\"output_type\": \"$data[15]\",
			\"submitted_file_name\": \"gz/$upload\",
			\"lab\": \"$data[17]\",
			\"award\": \"$data[16]\",
			\"read_length\": $data[10],
			\"platform\": \"/platforms/$data[19]/\"
		}";
	}
	close( OUT );
	`cp json.log ./$ARGV[0]_log/$id\_json.log`;	#backup
#==============================================================================#
# Submit json file to T2DREAM DB and heck if the submission is successful
#==============================================================================#
	print "sh submit_t2d.sh <json.log | tee ./$ARGV[0]_log/$id\_t2d.log >t2d.log\n";
	`sh submit_t2d.sh <json.log | tee ./$ARGV[0]_log/$id\_t2d.log >t2d.log`;	#sumbit json file to T2DREAM DB
	$jsonRef = json_file_to_perl( 't2d.log' );	#get hash reference for json file back from T2DREAM DB
	if( !defined( @$jsonRef{ 'status' } ) || @$jsonRef{ 'status' } !~ /success/ ){
		print OUTFAIL $id, "\n";
		die( "Check $id\n" );
	}
	`rm json.log`;
	print "./submit_aws.pl t2d.log | tee ./$ARGV[0]_log/$id\_aws.log >aws.log\n";
	`./submit_aws.pl t2d.log | tee ./$ARGV[0]_log/$id\_aws.log >aws.log`;
	print "bash aws.log\n";
	`bash aws.log`;
	print "Done $id\n\n";
	`rm t2d.log`;
	`rm aws.log`;
}close( IN );
