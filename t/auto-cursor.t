#!perl
use warnings;
use strict;
use Test::More;
use Net::Twitter;
use JSON::Any;
use HTTP::Response;

my $json_result = JSON::Any->to_json({ ids => ['test'], next_cursor => 1 });
sub mock_ua {
    my $nt = shift;


    $nt->ua->add_handler(request_send => sub {
        my $resp = HTTP::Response->new(200);
        $resp->content($json_result);
        return $resp;
    });
}

{
    my $nt_with_max_calls_2 = Net::Twitter->new(traits => ['API::REST',  AutoCursor => { max_calls => 2 }]);
    my $class_for_max_calls_2 = ref $nt_with_max_calls_2;

    my $nt_with_max_calls_4 = Net::Twitter->new(traits => ['API::REST',  AutoCursor => { max_calls => 4 }]);
    my $class_for_max_calls_4 = ref $nt_with_max_calls_4;

    my $json_result = JSON::Any->to_json({ ids => ['test'], next_cursor => 1 });

    mock_ua($_) for $nt_with_max_calls_2, $nt_with_max_calls_4;

    my $r = $nt_with_max_calls_2->friends_ids({ cursor => -1 });
    is scalar @$r, 2, 'max_calls => 2';

    $r = $nt_with_max_calls_4->friends_ids({ cursor => -1 });
    is scalar @$r, 4, 'max_calls => 4';

    $r = $nt_with_max_calls_4->followers_ids({ cursor => -1, max_calls => 10 });
    is scalar @$r, 10, 'max_calls per call override';

    my $nt = Net::Twitter->new(traits => ['API::REST',  AutoCursor => { max_calls => 2 }]);
    mock_ua($nt);
    is ref $nt, $class_for_max_calls_2, 'clone max_calls => 2, class name';
    $r = $nt->friends_ids({ cursor => -1 });
    is scalar @$r, 2, 'cloned max_calls => 2';

    $nt = Net::Twitter->new(traits => ['API::REST',  AutoCursor => { max_calls => 4 }]);
    mock_ua($nt);
    is ref $nt, $class_for_max_calls_4, 'clone max_calls => 4, class name';
    $r = $nt->friends_ids({ cursor => -1 });
    is scalar @$r, 4, 'cloned max_calls => 4';
}

done_testing;
