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
            shift;
            ++$profile_link_called;
            return "Agent " . uc(shift);
        }
    );

    my $bot = $CLASS->new( token => 'token' );

    subtest 'pm behaviour' => sub {

        my $msg = _new_msg( text => 'Dittosaur', chat => _new_private_chat() );

        like $bot->_dispatch( $msg ), qr/^Agent DITTOSAUR/, "Bare IGN works fine in PM";
        is $profile_link_called, 1, "...and we called the actual method";

        $msg->text( '/ada' );
        like $bot->_dispatch( $msg ), qr/^Agent __ADA__/, "And the NPC commands work";
        is $profile_link_called, 2, "...and we still call the method";

        $profile_link_called = 0; # reset

    };

    subtest 'group behaviour' => sub {

        my $msg = _new_msg( text => 'Dittosaur', chat => _new_group_chat() );
        my $reply = $bot->_dispatch( $msg );
        ok !defined $reply, "No response without a command, in group";

        $msg->text( '/jarvis' );
        like $bot->_dispatch( $msg ), qr/^Agent __JARVIS__/, "And the NPC commands work in groups";

        $msg->text( '/profile firstname surname' );
        like $bot->_dispatch( $msg ), qr/^Agent FIRSTNAME$/, "Profile command works correctly, ignores extra words";

    };

    $mock_bot->reset('_profile_link');

};

subtest 'profile link' => sub {
    my $bot = $CLASS->new( token => 'token' );
    
    like $bot->_profile_link(''), qr/understand what just/,
        "Bot is appropriately confused by impossible blank IGN";

    like $bot->_profile_link('Dittosaur'), qr|^Agent DITTO.+2FDittosaur$|,
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

sub _new_private_chat {
    return Telegram::Bot::Object::Chat->new( type => 'private', @_ );
}

sub _new_group_chat {
    return Telegram::Bot::Object::Chat->new( type => 'group', @_ );
}