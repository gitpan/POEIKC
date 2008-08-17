package SaC2;

use strict;
use warnings;
use 5.8.1;
our $VERSION = '0.01';

use Data::Dumper;
use Class::Inspector;
use POE qw(
	Sugar::Args
	Loop::IO_Poll
	Component::IKC::ClientLite
);
use base qw(Class::Accessor::Fast);

use POEIKC::Daemon::Utility;

__PACKAGE__->mk_accessors(qw/alias ikc_client_name connected/);

sub spawn
{
	my $class = shift;
	my $self  = $class->new();
	POEIKC::Daemon::Utility::_DEBUG_log(@_);
	my $session = POE::Session->create(
	    object_states => [ $self => Class::Inspector->methods(__PACKAGE__) ]
	);
	return $session->ID;
}

sub _start {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my $alias = __PACKAGE__.'_alias';
	POEIKC::Daemon::Utility::_DEBUG_log($alias);
	$object->alias($alias);
	$kernel->alias_set($alias);

	$kernel->sig( HUP  => '_stop' );
	$kernel->sig( INT  => '_stop' );
	$kernel->sig( TERM => '_stop' );
	$kernel->sig( KILL => '_stop' );

	$kernel->call(
		IKC =>
			#publish => $object->alias, Class::Inspector->methods(__PACKAGE__),
			publish => $object->alias, [qw/catch go_callback/],
	);

		$kernel->post(IKC=>'monitor', '*'=>{
			register	=>'monitor_callback_register',
			unregister	=>'monitor_callback_unregister',
		});
		$object->connected({})

}

sub _stop {
	my $poe = sweet_args;
}

sub monitor_callback_register
{
	my $poe = sweet_args ;
	my $object = $poe->object;
	my $client = (@{$poe->args})[1];
	$object->connected->{$client}++;
	POEIKC::Daemon::Utility::_DEBUG_log($object->connected);
}

sub monitor_callback_unregister
{
	my $poe = sweet_args ;
	my $object = $poe->object;
	my $client = (@{$poe->args})[1];
	delete $object->connected->{$client} if ref $object->connected and $object->connected->{$client};
	POEIKC::Daemon::Utility::_DEBUG_log($object->connected);
#	POEIKC::Daemon::Utility::_DEBUG_log(join " / ", map {$_ ? $_ : ''} @{$poe->args});
}

sub ikc_client_spawn {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my $client_name = __PACKAGE__.'_client_name';
	POEIKC::Daemon::Utility::_DEBUG_log($client_name);

	my $hash = {
		ip   => 'localhost', # 相手のホスト
		port => '1111' ,# 相手のポート
		name => $client_name, # 自分のクライアント名
		aliases => [$client_name.'_alias', $POEIKC::Daemon::opt{name}], # alias
		on_connect => sub {
			POEIKC::Daemon::Utility::_DEBUG_log('on_connect');
			#$kernel->post($session => 'go2');
		},
		on_error =>sub {
			POEIKC::Daemon::Utility::_DEBUG_log('on_error');
		},
	};
	POEIKC::Daemon::Utility::_DEBUG_log($hash);
	POE::Component::IKC::Client->spawn(%{$hash});
}


sub catch {
	my $poe     = sweet_args ;
	my ( @data ) = @{$poe->args} ;
	POEIKC::Daemon::Utility::_DEBUG_log(@data);
	return [$$, __PACKAGE__,__LINE__, \@data];
}

sub go {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session ;
	my $object = $poe->object;

	my $server = 'AAA';

	my $call = sprintf "poe://%s/%s/catch", $server, 'SaC1_alias';
	my $back = "poe:go_callback";

	POEIKC::Daemon::Utility::_DEBUG_log($call);
	POEIKC::Daemon::Utility::_DEBUG_log($back);

	$kernel->post('IKC', 'call', $call, $$.__PACKAGE__.':'.__LINE__, $back);
}


sub go_callback {
	my $poe 	= sweet_args;
	my ( @data ) = @{$poe->args} ;
		POEIKC::Daemon::Utility::_DEBUG_log(__PACKAGE__, $$);
		POEIKC::Daemon::Utility::_DEBUG_log(@data);
	return [$$, __PACKAGE__,__LINE__,\@data];
}




1;
__END__
