package POEIKC::Daemon::AndClient;

use strict;
use v5.8.1;

use warnings;
use Data::Dumper;
use UNIVERSAL::require;
use POE qw(
	Sugar::Args
	Loop::IO_Poll
	Component::IKC::Client
);

use POEIKC;
our $VERSION = $POEIKC::VERSION;
use POEIKC::Daemon;
use POEIKC::Daemon::Utility;

####


sub connect {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $object = $poe->object;
	my $session = $poe->session;
	my ( $server, $hash , $delay) = @{$poe->args} ;
	$delay ||= 0.2;

	return $POEIKC::Daemon::connected{$server} 
			if $server and $POEIKC::Daemon::connected{$server};

	$POEIKC::Daemon::DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($server, $delay, $hash);

	$object->create_client( $hash, $server );
	$kernel->delay(connect => $delay, $server, $hash, $delay); 
}


sub connected {
	my $self = shift;
	my $server = shift;
	return $POEIKC::Daemon::connected{$server};
}


sub create_client {
	my $self = shift;
	my $hash = shift;
	my $server = shift;

	return $POEIKC::Daemon::connected{$server} 
			if $server and $POEIKC::Daemon::connected{$server};

	if ( $hash->{aliases} ) {
		if (ref $hash->{aliases} eq 'ARRAY'){
			my $flag;
			for ( @{$hash->{aliases}} ) {
				$flag = 1 if $POEIKC::Daemon::opt{name} eq $_;
			}
			push @{$hash->{aliases}}, $POEIKC::Daemon::opt{name} if not $flag;
		}else{
			my $aliases = $hash->{aliases};
			$hash->{aliases} = [];
			push @{$hash->{aliases}}, ($aliases, $POEIKC::Daemon::opt{name});
		}
	}else{
		push @{$hash->{aliases}}, ($POEIKC::Daemon::opt{name});
	}
	
	$hash->{name} ||= $POEIKC::Daemon::opt{name} . join('_'=>__PACKAGE__ =~ m/(\w+)/g);

	$POEIKC::Daemon::DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($hash);

	POE::Component::IKC::Client->spawn(%{$hash});
}


1;
__END__

=head1 NAME

POEIKC::Daemon::AndClient - POE IKC daemon and client

=head1 SYNOPSIS

	package MyServerAndClient;

	use strict;
	use warnings;

	use Data::Dumper;
	use Class::Inspector;
	use POE qw(
		Sugar::Args
		Loop::IO_Poll
	);

	use base qw(POEIKC::Daemon::AndClient);

	use POEIKC::Daemon::Utility;

	sub new {
	    my $class = shift ;
	    my $self = {
	        @_
	        };
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

then ..

  poeikcd start -d -n=AAAA -p=1111 -I=eg/lib -M=MyServerAndClient
  poeikcd start -d -n=BBBB -p=2222 -I=eg/lib -M=MyServerAndClient

  poikc -p=1111 -D "AndClient->spawn"
  poikc -p=2222 -D "AndClient->spawn"

  poikc -p=1111 -D AAAA_alias server_connect BBBB 2222

  poikc -p=1111 -D AAAA_alias go BBBB 
  poikc -p=2222 -D BBBB_alias go AAAA 


=head1 DESCRIPTION

use it to communicate between poeikcd.

=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE::Component::IKC::Client>

=cut
