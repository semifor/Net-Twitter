package Net::Twitter::Role::AutoCursor;

use MooseX::Role::Parameterized;

parameter max_calls      => isa => 'Int',  default => 16;
parameter array_accessor => isa => 'Str',  default => 'ids';
parameter force_cursor   => isa => 'Bool', default => 0;
parameter methods        => isa => 'ArrayRef[Str]', default => sub { [qw/friends_ids followers_ids/] };

role {
    my $p = shift;

    requires @{$p->methods};

    my $around = sub {
        my $orig = shift;
        my $self = shift;

        my $args = ref $_[-1] eq ref {} ? pop : {};

        # backwards compat: all synthetic args use dash (-) prefix, now
        for ( qw/force_cursor max_calls/ ) {
            $args->{"-$_"} = delete $args->{$_} if exists $args->{$_};
        }

        # no change in behavior if the user passed a cursor
        return $self->$orig(@_, $args) if exists $args->{cursor};

        $args->{id} = shift if @_;

        my $force_cursor = exists $args->{-force_cursor} ? $args->{-force_cursor} : $p->force_cursor;
        $args->{cursor} = -1 if !exists $args->{cursor} && $force_cursor;

        my $max_calls = exists $args->{-max_calls} ? $args->{-max_calls} : $p->max_calls;

        my $calls = 0;
        my $results;
        if ( !exists $args->{cursor} ) {
            # try the old style, non-cursored call
            my $r = $orig->($self, $args);
            return $r if ref $r eq ref [];

            ++$calls;
            # If Twitter forces a cursored call, we'll get a HASH instead of an ARRAY
            $results = $r->{$p->array_accessor};
            $args->{cursor} = $r->{next_cursor};
        }

        while ( $args->{cursor} && $calls++ < $max_calls ) {
            my $r = $self->$orig($args);
            push @$results, @{$r->{$p->array_accessor}};
            $args->{cursor} = $r->{next_cursor};
        }

        return $results;
    };

    around $_, $around for @{$p->methods};
};

1;

__END__

=head1 NAME

Net::Twitter::Role::AutoCursor - Help transition to cursor based access to friends_ids and followers_ids methods

=head1 SYNOPSIS

  use Net::Twitter;
  my $nt = Net::Twitter->new(
      traits => [qw/AutoCursor API::RESTv1_1 RetryOnError OAuth/],
      # additional ags...
  );

  # Get friends_ids or followers_ids without worrying about cursors
  my $ids = $nt->followers_ids;

  my $nt = Net::Twitter->new(
      traits => [
          qw/API::RESTv1_1 RetryOnError OAuth/
          AutoCursor => { max_calls => 32 },
          AutoCursor => {
              max_calls      => 4,
              force_cursor   => 1,
              array_accessor => 'users',
              methods        => [qw/friends followers/],
          },
      ],
      # additional args
  );

  # works with any Twitter call that takes a cursor parameter
  my $friends = $nt->friends;

=head1 DESCRIPTION

On 25-Mar-2011, Twitter announced a change to C<friends_ids> and
C<followers_ids> API methods:

  [Soon] followers/ids and friends/ids is being updated to set the cursor to -1
  if it isn't supplied during the request. This changes the default response
  format

This will break a lot of existing code.  The C<AutoCursor> trait was created to
help users transition to cursor based access for these methods.

With default parameters, the C<AutoCursor> trait attempts a non-cursored call
for C<friends_ids> and C<followers_ids>.  If it detects a cursored
response from Twitter, it continues to call the underlying Twitter API method,
with the next cursor, until it has received all results or 16 calls have been
made (yielding 80,000 results).  It returns an ARRAY reference to the combined
results.

If the C<cursor> parameter is passed to C<friends_ids> or C<followers_ids>,
C<Net::Twitter> assumes the user is handling cursoring and does not modify
behavior or results.

The C<AutoCursor> trait is parameterized, allowing it to work with any Twitter
API method that expects cursors, returning combined results for up to the
maximum number of calls specified.

C<AutoCursor> can be applied multiple times to handle different sets of API
methods.

=head1 PARAMETERS

=over 4

=item max_calls

An integer specifying the maximum number of API calls to make. Default is 16.

C<max_calls> can be overridden on a per-call basis by passing a C<max_calls>
argument to the API method.

=item force_cursor

If true, when the caller does not provide a C<cursor> parameter, C<AutoCursor>
will use up to C<max_calls> cursored calls rather than attempting an initial
non-cursored call.  Default is 0.

=item array_accessor

The name of the HASH key used to access the ARRAY ref of results in the data
structure returned by Twitter.  Default is C<ids>.

=item methods

A reference to an ARRAY containing the names of Twitter API methods to which
C<AutoCursor> will be applied.

=back

=head1 METHOD CALLS

Synthetic parameter C<-max_calls> can be passed for individual method calls
to override the default:

  $r = $nt->followers_ids({ -max_calls => 200 }); # get up to 1 million ids

Synthetic parameter C<-force_cursor> can be passed to override the
C<force_cursor> default.

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT

Copyright (c) 2011 Marc Mims

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

