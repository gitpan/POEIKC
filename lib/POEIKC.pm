package POEIKC;

use strict;
use 5.8.1;
our $VERSION = '0.00_01';

1;
__END__

=head1 NAME

POEIKC - POE IKC daemon and client

=head1 SYNOPSIS

L<poeikcd> (daemon)

	poeikcd start -p=47225 
	poeikcd stop  -p=47225 
	poeikcd --help

And then 
L<poikc> (client) 

	poikc -H hostname [options] args...
	poikc --help

=head1 DESCRIPTION

L<poeikcd> is daemon of POE::Component::IKC.
And then L<poikc> is for poeikcd.

=head1 AUTHOR

Yuji Suzuki E<lt>yuji.suzuki.perl@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE>
L<POE::Component::IKC>
L<POE::Component::IKC::Server>

=cut
