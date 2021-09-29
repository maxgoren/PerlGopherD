#!/usr/bin/perl
use IO::Socket;
my $name = "PerlGopher v0.1"; #servername
my $port = 7070;               #Gopher default port 70
my $dir = "./*";               #default Gopher directory
my $lineend = "\r\n";

my $server = IO::Socket::INET->new(LocalPort => $port,
				   Type => SOCK_STREAM,
				   Reuse => 1,
				   Listen => 10 )
   or die "Can't open server on port $port : $1 \n";

while ($client = $server->accept()) {
  $remote_addr = $client->peerhost();
  print "New Connction from: $remote_addr\n";
  $request = <$client>;  
  &requestHandler($client, $request, $dir);
}


sub requestHandler { 

   my ($client, $request, $dir) = @_;
   my $shouldserv = "nil"; 
   print "Revieved request: " . $request;

   $localhost = $client->sockhost(); #server address

   @dirlist = glob ( $dir ); #read file directory

   foreach $file (@dirlist) {
	$file =~ s/^.\///; #remove preceding directory
        chomp($file);
        if ($request =~ /$file/)  #check if request is for available file
        {
          $shouldserv = $file; #designate file to be served up
        }
   }

   if ($shouldserv ne "nil") #if a file has been requested
   {
	#send over the file as plain text
        print "Sending File: $shouldserv\n";
	open(FILE, $shouldserv);
        @toSend = <FILE>;
        close(FILE);
        foreach (@toSend) {
	   print $client $_, "\n";
        }
   } else { #if not, 
     #send over the current directory as a gophermap
     foreach $file (@dirlist) {
        if ( -d $file) {
          #format proper selector response
          $reply = "1" . $file . "\t" . $file . "\t". $localhost . "\t" . $port;
        }
        if ( -f $file) {
          $reply = "0" . $file . "\t". $file . "\t" . $localhost . "\t".$port;
        }
        print $reply . $lineend;
        print $client $reply . $lineend;
     }
   }
   #close connection
   $client->close();
}

