use strict;
use Test::More;
use POEIKC::Daemon;
use POEIKC::Daemon::P2P;

use strict;
use lib qw(t);
use Data::Dumper;
use Errno qw(EAGAIN);

eval q{ use Demo::P2P };
plan skip_all => "Demo::P2P is not installed." if $@;

use POE qw(Component::IKC::ClientLite);
use POEIKC::Daemon;
use POEIKC::Client;

######################

$| = 1;

my @options = (
  "./bin/poeikcd start -n=ServerA -p=47225 -I=t:lib -M=Demo::P2P ",
  "./bin/poeikcd start -n=ServerB -p=47226 -I=t:lib -M=Demo::P2P ",
);

my @pid;
######################
# fork
foreach my $options (@options){
	 `$options`;
}

######################

	sleep 1;

	my @client_opt;
	for ( 47225, 47226 ){
		my ($name) = $0 =~ /(\w+)\.\w+/;
		$name .= $$ . sprintf "%02d",$_;
		my %cicopt = (
			ip => '127.0.0.1',
			port => $_,
			name => $name,
		);
		push @client_opt, \%cicopt;
	}
	my @ikc;
	for (@client_opt){
		my $ikc = create_ikc_client(%{$_});
		$ikc or plan skip_all => '';
		push @ikc, $ikc;
	}


	my $sa = $ikc[0]->post_respond( 'POEIKCd/something_respond' => ['Demo::P2P->spawn'] );
	my $sb = $ikc[1]->post_respond( 'POEIKCd/something_respond' => ['Demo::P2P->spawn'] );

	$sa = $ikc[0]->post_respond( 'POEIKCd/something_respond' => ['ServerA_alias','server_connect','ServerB','47226'] );

sleep 1;

#		print Dumper $ikc[0];
#		print Dumper $ikc[1];

	$sa = $ikc[0]->post_respond( 'POEIKCd/something_respond' => ['ServerA_alias','go','ServerB'] );
	$sb = $ikc[1]->post_respond( 'POEIKCd/something_respond' => ['ServerB_alias','go','ServerA'] );

	$sa = $ikc[0]->post_respond( 'POEIKCd/something_respond' => ['ServerA_alias','get'] );
	$sb = $ikc[1]->post_respond( 'POEIKCd/something_respond' => ['ServerB_alias','get'] );
#print "\nsa=> $sa\n", Dumper $sa;
#print "\nsb=> $sb\n", Dumper $sb;
ref $sa ne 'HASH' and plan skip_all => '';
ref $sb ne 'HASH' and plan skip_all => '';

plan tests => 2;
is($sa->{this_pid} , $sb->{catch}->{PID}, "PID");
is($sb->{this_pid} , $sa->{catch}->{PID}, "PID");

######################
# shutdown
	for my $ikc ( @ikc ) {
		$ikc->post_respond('POEIKCd/method_respond',
			['POEIKC::Daemon::Utility','shutdown']
		);
		$ikc->error and die($ikc->error);
	}

 ` pkill -f poeikcd`;

1;

__END__

 poeikcd start -f -n=ServerA -p=47225 -I=eg/lib:lib:t -M=Demo::P2P
 poeikcd start -f -n=ServerB -p=47226 -I=eg/lib:lib:t -M=Demo::P2P

  poikc -p=47225 -D "Demo::P2P->spawn"
  poikc -p=47226 -D "Demo::P2P->spawn"

  poikc -p=47225 -D ServerA_alias server_connect ServerB 47226

  poikc -p=47225 -D ServerA_alias go ServerB
  poikc -p=47226 -D ServerB_alias go ServerA




$   poikc -p=47225 -D "Demo::P2P->spawn"
# $ikc_client->post_respond( 'POEIKCd/something_respond' => ['Demo::P2P->spawn'] );

$   poikc -p=47226 -D "Demo::P2P->spawn"
# $ikc_client->post_respond( 'POEIKCd/something_respond' => ['Demo::P2P->spawn'] );

$   poikc -p=47225 -D ServerA_alias server_connect ServerB 47226
# $ikc_client->post_respond( 'POEIKCd/something_respond' => ['ServerA_alias','server_connect','ServerB','47226'] );

$   poikc -p=47225 -D ServerA_alias go ServerB
# $ikc_client->post_respond( 'POEIKCd/something_respond' => ['ServerA_alias','go','ServerB'] );

$   poikc -p=47226 -D ServerB_alias go ServerA
# $ikc_client->post_respond( 'POEIKCd/something_respond' => ['ServerB_alias','go','ServerA'] );

