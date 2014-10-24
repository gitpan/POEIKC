use Test::Base;
use strict;
use lib qw(t);
eval q{ use Demo::Loop };
plan skip_all => "Demo::Loop is not installed." if $@;

#eval q{ use Cache::FastMmap::Tie };
#plan skip_all => "Cache::FastMmap::Tie is not installed." if $@;

use POE qw(
	Component::IKC::ClientLite
);

use POEIKC::Daemon;
use Data::Dumper;
use Errno qw(EAGAIN);
my $DEBUG = shift || '';

$| = 1;

#  'debug' => $DEBUG,
my $options = {
  'INC' => [
             './t'
           ],
  'alias' => 'POEIKCd',
  'port' => 47225
};

if ($DEBUG) {
	$DEBUG =~ /a/i ? $options->{debug}=1 : $DEBUG=1;
}

my $pid;
FORK: {
	if( $pid = fork ) {
	} elsif (defined $pid) {
		POEIKC::Daemon->daemon(%{$options});
	    exit;
	} elsif ( $! == EAGAIN) {
	    sleep 1;
	    redo FORK;
	} else {
	    die "Can't fork: $\n";
	}
} # End Of Label:FORK

	sleep 1;
		*POEIKC::Daemon::Utility::DEBUG = $DEBUG;

		my ($name) = $0 =~ /(\w+)\.\w+/;
		$name .= $$;
		my %cicopt = (
			ip => '127.0.0.1',
			port => $options->{port},
			name => $name,
		);

		$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(\%cicopt);

		if( Proc::ProcessTable->use ){
			for my $ps( @{Proc::ProcessTable->new->table} ) {
				if ($ps->{pid} != $$ and $ps->{fname} eq 'poeikcd'){
					plan skip_all => $ps->{cmndline}." .... already running \n";
					die;
				}
			}
		}

		my $ikc = create_ikc_client(%cicopt);
		$ikc ? 	plan(tests => 1 * blocks) : plan skip_all => '';

		my $r;
		my $c;
		run {
			my $t = shift;
			my ($no, $type, $state, $name, $comment) = split /\t/, $t->name ;
			
			my $i = $t->input ;
			my $e;
			my $seq_num = $t->seq_num ;

			$r = $ikc->post_respond(
				$state => eval $i) if $type ne 'pass';
				$ikc->error and die($ikc->error);
			
			eval $state if defined $state and $type eq 'pass';

			$e = $type ne 'like' ? eval $t->expected : $t->expected;
			$e = ref $e ? Dumper($e):$e;
			$r = ref $r ? Dumper($r):$r;

			for ($type) {
				$_ eq 'isnt'	and isnt($r , $e, $name), last;
				$_ eq 'is'		and is	($r , $e, $name), last;
				$_ eq 'ok_r'	and ok	($r ,     $name), last;
				$_ eq 'ok_e'	and ok	($e ,     $name), last;
				$_ eq 'like'	and like($r , qr/$e/, $name ), last; # ."\t like($r, qr/$e/)"
			}
			$type eq 'pass'	and pass('...');
		};

		$ikc->post_respond($options->{alias}.'/method_respond', 
			['POEIKC::Daemon::Utility','shutdown']
		);
		$ikc->error and die($ikc->error);

    #wait;
	waitpid($pid, 0);

__END__

=== 1	is	POEIKCd/method_respond	POEIKC::Daemon::Utility=>get_VERSION
--- input: ['POEIKC::Daemon::Utility' => 'get_VERSION']
--- expected: $POEIKC::Daemon::VERSION

=== 2	is	POEIKCd/method_respond	'POEIKCd/method_respond' => ['POEIKC::Daemon::Utility','loop','5','Demo::Loop::loop_test','987']
--- input: ['POEIKC::Daemon::Utility','loop','5','Demo::Loop::loop_test','987']
--- expected: 'Demo_loop_test_loop'

=== 3	ok_e	POEIKCd/something_respond	'POEIKCd/something_respond' => ['Demo::Loop::get'] 
--- input: ['Demo::Loop::get']
--- expected: $r->{loop_cut} == 5

=== 4	ok_e	POEIKCd/something_respond	'POEIKCd/something_respond' => ['Demo::Loop::get'] 
--- input: ['Demo::Loop::get']
--- expected: $r->{loop_list}->[0] == 987

=== 5	ok_e	POEIKCd/something_respond	'POEIKCd/something_respond' => ['Demo::Loop::get'] 
--- input: ['Demo::Loop::get']
--- expected: $r->{loop_list}->[1] == 1

=== 5	ok_e	POEIKCd/something_respond	'POEIKCd/something_respond' => ['Demo::Loop::get'] 
--- input: ['Demo::Loop::get']
--- expected: $r->{loop_list}->[2] == 2
