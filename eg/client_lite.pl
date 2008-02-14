#!/usr/local/bin/perl

###	perl -I t -I lib -MPOEIKC::Daemon -e POEIKC::Daemon::daemon

use strict;
use warnings;
$| = 1;
use POE::Component::IKC::ClientLite;
use Data::Dumper;
use Sys::Hostname;
use Getopt::Long;
use Pod::Usage;

my $options = {};

BEGIN {
	$Getopt::Long::ignorecase=0;
	$options = {};
	GetOptions ($options, qw/
		HOST=s 
		port=i 
		alias=s
		debug
		help
		/);
}
	my $menu = shift;

	$options->{help} and pod2usage(1);

	$options->{alias} ||= 'POEIKCd';
	$options->{port} ||= 47225;
	$options->{state_name} ||= 'method_respond';
	$options->{HOST} ||= '127.0.0.1';
	$options->{state_name} = 
		$options->{state_name} =~ /^m/i ? 'method_respond' : 
		$options->{state_name} =~ /^f/i ? 'function_respond' : pod2usage(1);

	print scalar localtime,"\n";
	printf "[poeikcd ..  %s / PORT:%s]\n", $options->{HOST}, $options->{port};

	my ($name) = $0 =~ /(\w+)\.\w+/;
	$name .= $$;
	my $ikc = create_ikc_client(
			ip => $options->{host},
			port => $options->{port},
			name => $name,
	);

	$ikc or do{
		printf "%s\n\n",$POE::Component::IKC::ClientLite::error; 
		pod2usage(1);
	};

	my $ret;
	my $nom=0;
	my %exe = map {$nom++=>$_}
	(
		['Foo::Class'=>'FooMethod'=>'@args'],
		['POEIKC::Daemon::Utility' => 'reload', 'POEIKC::Daemon::Utility'],
		['POEIKC::Daemon::Utility' => 'get_H_ENV'],
		['POEIKC::Daemon::Utility' => 'get_A_INC'],
		['POEIKC::Daemon::Utility' => 'unshift_INC', './t'],
		['POEIKC::Daemon::Utility' => 'unshift_INC', '~/lib'],
		['POEIKC::Daemon::Utility' => 'delete_INC', './t'],
		['POEIKC::Daemon::Utility' => 'reset_INC'],
		['POEIKC::Daemon::Utility' => 'get_H_INC'],
		['POEIKC::Daemon::Utility' => 'get_pid'],
		['POEIKC::Daemon::Utility' => 'get_object_something', 'ikc_self_port'],
		['POEIKC::Daemon::Utility' => 'get_object_something', 'session_alias'],
		['POEIKC::Daemon::Utility' => 'get_stay'],
		['POEIKC::Daemon::Utility' => 'get_VERSION'],
		['POEIKC::Daemon::Utility' => 'stop'],
		['Cwd' => 'getcwd'],
		['IKC_d_Localtime' => 'timelocal'],
		['POEIKC::Daemon::Utility' => 'reload', 'IKC_d_Localtime'],
		['POEIKC::Daemon::Utility' => 'reload', 'IKC_d_Localtime' => 'timelocal'],
		['POEIKC::Daemon::Utility' => 'stay', 'IKC_d_Localtime' ],
		['POEIKC::Daemon::Utility' => 'get_Class_Inspector', 'POEIKC::Daemon::Utility'],
		['POEIKC::Daemon::Utility' => 'get_Class_Inspector', 'POEIKC::Daemon::Utility','methods'],
		['Cwd' => 'getcwd'],
		['LWP::Simple' => 'get', 'http://search.cpan.org/~suzuki/'],
	);


	printf "%2d => %s\n", $_, join("\t"=> @{$exe{$_}}) for sort {$a<=>$b} keys %exe;

	print '*' x 20, "\n";

	$menu or printf("\n    perl eg/client_lite.pl [1 .. %d]\n\n", scalar(keys %exe)-1), exit;

	printf "[%d]\t%s\n", $menu, join "\t"=>@{$exe{ $menu }};

	my $session_alias = $options->{alias} || 'POEIKCd';
	
	my $event = $menu <= 15 ? 'method_respond' : 'function_respond';
	print $event,"\n";

	$ret = $ikc->post_respond($session_alias.'/'.$event => $exe{ $menu });

	$ikc->error and die($ikc->error);
	if (my $r = ref $ret) {
		if ( $r eq 'HASH'){
			my %ret = %{$ret};
			for(sort keys %ret){printf "%-35s= %s", $_, Dumper $ret{$_}}
			print "\n";
		}else{
			print(Dumper($ret));
		}
	}else{
		print(Dumper($ret));
	}

__END__

=head1 SYNOPSIS

  Options:

	-H  --HOST=s        : default 127.0.0.1 

    -p  --port=#        : Port number to use for connection.
                          default 47224 

    -a  --alias=s       : session alias
                          default POEIKCd 

    -h  --help

=cut
