package DBMedit;


my $end = sub {
	warn('--END--');
	dbmclose(%DBM) if %DBM; # DBMがまだクローズされていなければ
	die @_ if @_; # SIGINTの場合、エラー文字列を受け取る
};
$SIG{INT} = $end;
END {$end->();}

my $DBM     = {};
my $db_path = {}; # name=>path
my $name;
sub dbmopen {
	$name = shift ;
	$db_path->{$name} = shift;
	$db_path->{$name} or return 'parameter error .. dbmopen($name, $dbm_file_fullpath) ';
	
	dbmopen(%{$DBM->{$name}}, $db_path->{$name}, 0666) || join "\t"=>( $! , $db_path );
	return scalar keys %{$DBM->{$name}};
}

sub path { return $db_path }
sub name { $name = shift || return $name}

sub keys {
	@_ or return 'parameter error .. keys($offset, $length) count=>'. scalar keys %{$DBM->{$name}};
	my ($offset, $length ) = @_;
	return (keys %{$DBM->{$name}})[$offset .. $length];
}

sub get {
	my $key = shift;
	return $DBM->{$name}->{$key};
}

sub count {return scalar keys %{$DBM->{$name}};}

1;

