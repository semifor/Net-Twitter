package Net::Twitter::Role::API::Lists;
use Moose::Role;
use DateTime::Format::Strptime;

requires qw/username ua/;

has lists_api_url => ( isa => 'Str', is => 'rw', default => 'http://twitter.com' );
has _lists_dt_parser => ( isa => 'Object', is => 'rw', default => sub {
        DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y')
    }
);

#args *name, mode
sub create_list {
    my ($self, $args) = @_;
    my $user = $self->username;
    my $base = $self->lists_api_url;

    my $uri = URI->new(join '/', $base, $user, 'lists.json');

    my $res = $self->_authenticated_request('POST', $uri, $args, 1);

    return $self->_parse_result($res, {}, $self->_lists_dt_parser);
}
    
1;
