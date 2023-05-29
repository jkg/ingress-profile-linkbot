use strict;
use warnings;
use Test2::V0 -target => 'IngressLinkBot';
use Test2::Tools::Mock qw/mock_accessors/;

use Telegram::Bot::Object::Chat ();
use Telegram::Bot::Object::User ();

my $mock_bot = mock 'IngressLinkBot' => (
    track => 1,
    override => [
        think => sub {return},
        init => sub {return},
    ]
);

my $mock_msg = mock 'Telegram::Bot::Object::Message' => (
    track => 1,
    add => [ mock_accessors('_reply') ],
    override => [ reply => sub { $_[0]->_reply( $_[1] ) } ]
);

subtest 'instantiate' => sub {
    isa_ok $CLASS->new, 'IngressLinkBot', 'Telegram::Bot::Brain';
};

subtest 'dispatching' => sub {

    my $profile_link_called = 0;
    $mock_bot->override(
        _profile_link => sub {
            ++$profile_link_called;
            return "looks good";
        },
    );

    my $bot = $CLASS->new( token => 'token' );

    subtest 'text cases' => sub {

        my $msg = _new_msg( text => 'too many words' );
        like $bot->_dispatch( $msg ), qr/look like an agent name/, "Encourage user to try again on bad text";

        $msg = _new_msg( text => '' );
        like $bot->_dispatch( $msg ), qr/look like an agent name/, "... and also on blank message";

        $msg = _new_msg( text => '🍟');
        like $bot->_dispatch( $msg ), qr/look like an agent name/, "... and also with unexpected characters";

        $msg = _new_msg( text => 'é');
        like $bot->_dispatch( $msg ), qr/look like an agent name/, "... and also with unpermitted characters";

        is $profile_link_called, 0, "... and none of these cases called _profile_link";

        $msg = _new_msg( text => 'Dittosaur' );
        like $bot->_dispatch( $msg ), qr/looks good/, "But an IGN works fine";
        is $profile_link_called, 1, "...and we called the actual method";

        $msg = _new_msg( text => '  Dittosaur     ' );
        like $bot->_dispatch( $msg ), qr/looks good/, "...and extra whitespace is permitted";
        is $profile_link_called, 2, "...and we called the actual method again";

    };

    $mock_bot->reset('_profile_link');

};

subtest 'profile link' => sub {
    my $bot = $CLASS->new( token => 'token' );
    
    like $bot->_profile_link(''), qr/understand what just/,
        "Bot is appropriately confused by impossible blank IGN";

    like $bot->_profile_link('Dittosaur'), qr|referring to agent|,
        "... and generates a sane URL otherwise";

};

done_testing();

sub _new_msg {
    my %args = @_;
    unless ( defined $args{from} ) {
        $args{from} = _user_from_tgid();
    }
    return Telegram::Bot::Object::Message->new(%args);
}

sub _user_from_tgid {
    my $telegram_id = shift // -1;
    return Telegram::Bot::Object::User->new( id => $telegram_id );
}

