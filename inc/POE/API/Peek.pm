#line 1
# $Id: Peek.pm 621 2005-12-10 22:50:26Z sungo $
package POE::API::Peek;

#line 26

use 5.006001;
use warnings;
use strict;

our $VERSION = '2.'.sprintf "%04d", (qw($Rev: 20 $))[1];

BEGIN {
	use POE;
	if($POE::VERSION < '0.38') {
		die(__PACKAGE__." is only certified for POE version 0.38 and up and you are running POE version " . $POE::VERSION . ". Check CPAN for an appropriate version of ".__PACKAGE__.".");
	}
}

use POE;
use POE::Queue::Array;
use Devel::Size qw(total_size);
$Devel::Size::warn = 0;

# new {{{

#line 54

sub new { return bless {}, shift; }

# }}}

# id() {{{

#line 69

sub id { return $poe_kernel->ID }

# }}}

# Kernel fun {{{

#line 79

# is_kernel_running {{{

#line 92

sub is_kernel_running {
	my $kr_run_warning = ${ $poe_kernel->[ POE::Kernel::KR_RUN() ] };

	if($kr_run_warning |= POE::Kernel::KR_RUN_CALLED()) {
		return 1;
	} else {
		return 0;
	}
}

#}}}

# active_event {{{

#line 114

sub active_event { 
	return ${ $poe_kernel->[ POE::Kernel::KR_ACTIVE_EVENT() ] }; 
}

#}}}

# kernel_memory_size {{{

#line 131

sub kernel_memory_size {
	return total_size($poe_kernel);
}
# }}}

# event_list {{{

#line 148

sub event_list {
	my $self = shift;
   
	my %events;
	foreach my $session_ref (keys %{ $poe_kernel->[ &POE::Kernel::KR_SESSIONS() ] }) {
		my $session = $poe_kernel->[ &POE::Kernel::KR_SESSIONS() ]->{ $session_ref }->[ &POE::Kernel::SS_SESSION() ];
		next if $session->isa('POE::Kernel');
		my $id = $session->ID;

		my @events = sort keys %{ $session->[ &POE::Session::SE_STATES() ] };

		$events{ $id } = \@events;
	}

	return \%events;
}
# }}}

# which_loop {{{

#line 177

sub which_loop {
	return POE::Kernel::poe_kernel_loop();
}

#}}}


# }}}

# Session fun {{{

#line 192

# current_session {{{

#line 203

# the value of KR_ACTIVE_SESSION is a ref to a scalar. so we deref it before 
# handing it to the user.

sub current_session { return ${ $poe_kernel->[POE::Kernel::KR_ACTIVE_SESSION] } }

# }}}

# get_session_children {{{

#line 224

sub get_session_children {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_ses_get_children($session);
}
# }}}

# is_session_child {{{

#line 247

sub is_session_child {
	my $self = shift;
	my $parent = shift or return undef;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_ses_is_child($parent, $session);
}
# }}}

# resolve_session_to_ref {{{

#line 269

sub resolve_session_to_ref {
	my $self = shift;
	my $id = shift || $self->current_session()->ID;
	return $poe_kernel->_data_sid_resolve($id);
}
# }}}

# resolve_session_to_id {{{

#line 290

sub resolve_session_to_id {
    my $self = shift;
    my $session = shift || $self->current_session();
    return $poe_kernel->_data_ses_resolve_to_id($session);
}
# }}}

# get_session_refcount {{{

#line 310

sub get_session_refcount {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_ses_refcount($session);
}
# }}}

# session_count {{{

#line 330

sub session_count {
	return $poe_kernel->_data_ses_count();
}
# }}}

# session_list {{{

#line 349

sub session_list {
	my @sessions;
	my $kr_sessions = $POE::Kernel::poe_kernel->[POE::Kernel::KR_SESSIONS];
	foreach my $key ( keys %$kr_sessions ) {
		next if $key =~ /POE::Kernel/;
		push @sessions, $kr_sessions->{$key}->[0];
	}
	return @sessions;
}
# }}}

# session_memory_size {{{

#line 375

sub session_memory_size {
	my $self = shift;
	my $session = shift || $self->current_session();
	return total_size($session);
}
# }}}}

# session_event_list {{{

#line 396

sub session_event_list {
	my $self = shift;
	my $session = shift || $self->current_session();
	my @events = sort keys %{ $session->[ &POE::Session::SE_STATES() ] };

	if(wantarray) {
		return @events;
	} else {
		return \@events;
	}
}
# }}}

# }}}

# Alias fun {{{

#line 417

# resolve_alias {{{

#line 429

sub resolve_alias {
	my $self = shift;
	my $alias = shift or return undef;
	return $poe_kernel->_data_alias_resolve($alias);
}
# }}}

# session_alias_list {{{

#line 449

sub session_alias_list {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_alias_list($session);
}
# }}}

# session_alias_count {{{

#line 469

sub session_alias_count {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_alias_count_ses($session);
}
# }}}

# session_id_loggable {{{

#line 489

sub session_id_loggable {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_alias_loggable($session);
}
# }}}

# }}}

# Event fun {{{

#line 504

# event_count_to {{{

#line 517

sub event_count_to {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_ev_get_count_to($session);    
}
#}}}

# event_count_from {{{

#line 537

sub event_count_from {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_ev_get_count_from($session);    
}

#}}}

# event_queue {{{

#line 556

sub event_queue { return $poe_kernel->[POE::Kernel::KR_QUEUE] }

# }}}

# event_queue_dump {{{

#line 606

sub event_queue_dump { 
	my $self = shift;
	my $queue = $self->event_queue;
	my @happy_queue;

	for (my $i = 0; $i < @$queue; $i++) {
		my $item = {};
		$item->{ID} = $queue->[$i]->[ITEM_ID];
		$item->{index} = $i;
		$item->{priority} = $queue->[$i]->[ITEM_PRIORITY];

		my $payload = $queue->[$i]->[ITEM_PAYLOAD];
		my $ev_name = $payload->[POE::Kernel::EV_NAME()];
		$item->{event} = $ev_name;
		$item->{source} = $payload->[POE::Kernel::EV_SOURCE];
		$item->{destination} = $payload->[POE::Kernel::EV_SESSION];

		my $type = $payload->[POE::Kernel::EV_TYPE()];
		my $type_str;
		if ($type & POE::Kernel::ET_START()) {
			$type_str = '_start';
		} elsif ($type & POE::Kernel::ET_STOP()) {
			$type_str = '_stop';
		} elsif ($type & POE::Kernel::ET_SIGNAL()) {
			$type_str = '_signal';
		} elsif ($type & POE::Kernel::ET_GC()) {
			$type_str = '_garbage_collect';
		} elsif ($type & POE::Kernel::ET_PARENT()) {
			$type_str = '_parent';
		} elsif ($type & POE::Kernel::ET_CHILD()) {
			$type_str = '_child';
		} elsif ($type & POE::Kernel::ET_SCPOLL()) {
			$type_str = '_sigchld_poll';
		} elsif ($type & POE::Kernel::ET_ALARM()) {
			$type_str = 'Alarm';
		} elsif ($type & POE::Kernel::ET_SELECT()) {
			$type_str = 'File Activity';
		} else {
			if($POE::VERSION <= 0.27) {
				if($type & POE::Kernel::ET_USER()) {
					$type_str = 'User';
				} else {
					$type_str = 'Unknown';
				}
			} else {
				if($type & POE::Kernel::ET_POST()) {
					$type_str = 'User';
				} elsif ($type & POE::Kernel::ET_CALL()) {
					$type_str = 'User (not enqueued)';
				} else {
					$type_str = 'Unknown';
				}
			}
		}
        
		$item->{type} = $type_str;
		push @happy_queue, $item;
	}

	return @happy_queue;
} #}}}



# }}}

# Extref fun {{{

#line 678

# extref_count {{{

#line 689

sub extref_count {
	return $poe_kernel->_data_extref_count();
}
# }}}

# get_session_extref_count {{{

#line 707

sub get_session_extref_count {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_extref_count_ses($session);
}
# }}}

# }}}

# Filehandles Fun {{{

#line 722

# is_handle_tracked {{{

#line 733

sub is_handle_tracked {
	my($self, $handle, $mode) = @_;
	return $poe_kernel->_data_handle_is_good($handle, $mode);
}
# }}}

# handle_count {{{

#line 750

sub handle_count {
	return $poe_kernel->_data_handle_count();
}
# }}}

# session_handle_count {{{

#line 768

sub session_handle_count {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_handle_count_ses($session);
}
# }}}

# }}}

# Signals Fun {{{

#line 783

# get_safe_signals {{{

#line 794

sub get_safe_signals {
	return $poe_kernel->_data_sig_get_safe_signals();
}
# }}}

# get_signal_type {{{

#line 813

sub get_signal_type {
	my $self = shift;
	my $sig = shift or return undef;
	return $poe_kernel->_data_sig_type($sig);
}
# }}}

# is_signal_watched {{{

#line 831

sub is_signal_watched {
	my $self = shift;
	my $sig = shift or return undef;
	return $poe_kernel->_data_sig_explicitly_watched($sig);
}
# }}}

# signals_watched_by_session {{{

#line 853

sub signals_watched_by_session {
	my $self = shift;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_sig_watched_by_session($session);
}
# }}}

# signal_watchers {{{

#line 872

sub signal_watchers {
	my $self = shift;
	my $sig = shift or return undef;
	return $poe_kernel->_data_sig_watchers($sig);
}
# }}}

# is_signal_watched_by_session {{{

#line 893

sub is_signal_watched_by_session {
	my $self = shift;
	my $signal = shift or return undef;
	my $session = shift || $self->current_session();
	return $poe_kernel->_data_sig_is_watched_by_session($signal, $session);
}
# }}}

# }}}


1;
__END__

#line 949

# sungo // vim: ts=4 sw=4 noet
