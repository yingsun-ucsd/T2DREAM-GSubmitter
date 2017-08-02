#!/usr/bin/perl

while (<>) { chomp();
  $json.=$_;
}

die $json unless $json=~/"access_key": "(\S+)"/; print "export AWS_ACCESS_KEY_ID=$1\n";
die $json unless $json=~/"secret_key": "(\S+)"/; print "export AWS_SECRET_ACCESS_KEY=$1\n";
die $json unless $json=~/"session_token": "(\S+)"/; print "export AWS_SECURITY_TOKEN=$1\n";
die $json unless $json=~/"submitted_file_name": "(\S+)"/; $gz=$1;
die $json unless $json=~/"upload_url": "(\S+)"/; print "aws s3 cp $gz $1\n";
print "echo $gz >> submitted.txt\n";p
