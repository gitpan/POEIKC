package MyP2P;

use strict;
use warnings;
use Data::Dumper;
use Class::Inspector;
use POE qw(Sugar::Args Loop::IO_Poll);
use base qw(POEIKC::Daemon::P2P);
use POEIKC::Daemon::Utility;

sub new {
    my $class = shift ;
    my $self = {};
    $class = ref $class if ref $class;
    bless  $self,$class ;
    return $self ;
}

sub spawn
{
	my $class = shift;
	my $self  = $class->new();
	my $session = POE::Session->create(
	    object_states => [ $self => Class::Inspector->methods(__PACKAGE__) ]
	);
	return $session->ID;
}

sub _start {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $object  = $poe->object ;
	my $alias   = $POEIKC::Daemon::opt{name}.'_alias';
	$kernel->alias_set($alias);

	$kernel->call(
		IKC =>
			publish => $alias, Class::Inspector->methods(__PACKAGE__),
	);
}

sub catch {
	my $poe     = sweet_args ;
	my ( @data ) = @{$poe->args} ;
	POEIKC::Daemon::Utility::_DEBUG_log(@data);
	return [[$$, __PACKAGE__,__LINE__], \@data];
}

sub server_connect {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session;
	my $object = $poe->object;
	my ( $server, $port  ) = @{$poe->args} ;

	$server or die;
	$port or die;

	my $hash_param =	{
		ip   => 'localhost',
		port => $port ,
		on_connect => sub {
			POEIKC::Daemon::Utility::_DEBUG_log('on_connect');
		},
		on_error =>sub {
			POEIKC::Daemon::Utility::_DEBUG_log('on_error');
		},
	};

	$kernel->yield(connect=> $server, $hash_param) unless $object->connected($server);

}

sub go {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session;
	my $object = $poe->object;
	my ( $server, $port  ) = @{$poe->args} ;

#	$server or die;
#	$port or die;
#
#	my $hash_param =	{
#		ip   => 'localhost',
#		port => $port ,
#		on_connect => sub {
#			$kernel->post($session, 'go', $server, $port );
#			POEIKC::Daemon::Utility::_DEBUG_log('on_connect');
#		},
#		on_error =>sub {
#			POEIKC::Daemon::Utility::_DEBUG_log('on_error');
#		},
#	};
#
#	if ( not $object->connected($server) ) {
#		$kernel->yield(connect=> $server, $hash_param, 0.1);
#		return;
#	}

	my $call = sprintf "poe://%s/%s/catch", $server, $server.'_alias';
	my $back = "poe:callback";

	POEIKC::Daemon::Utility::_DEBUG_log([$call, $back]);

	$kernel->post('IKC', 'call', $call, $$.__PACKAGE__.':'.__LINE__, $back);
}

sub callback {
	my $poe 	= sweet_args;
	my ( @data ) = @{$poe->args} ;
	POEIKC::Daemon::Utility::_DEBUG_log( [[$$, __PACKAGE__, __LINE__], \@data]);
}

1;
__END__

  poeikcd start -d -n=ServerA -p=1111 -I=eg/lib:lib -M=MyP2P
  poeikcd start -d -n=ServerB -p=2222 -I=eg/lib:lib -M=MyP2P

  poikc -p=1111 -D "MyP2P->spawn"
  poikc -p=2222 -D "MyP2P->spawn"

  poikc -p=1111 -D ServerA_alias server_connect ServerB 2222
        or  poikc -p=2222 -D ServerB_alias server_connect ServerA 1111

  poikc -p=1111 -D ServerA_alias go ServerB
  poikc -p=2222 -D ServerB_alias go ServerA

