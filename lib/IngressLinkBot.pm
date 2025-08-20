package IngressLinkBot;
use Mojo::Base 'Telegram::Bot::Brain';
use URI::Encode qw|uri_encode|;

use Try::Tiny;

=head1 NAME

IngressLinkBot - a simple TG bot to generate deep-links for the Ingress client
from other inputs.

=head1 DESCRIPTION

Currently this TG bot simply takes a string that looks plausibly like an
Ingress username, and provides a link to that profile (which may or may not
actually exist!).

Maybe in the future it can do something with portal links? But those require
a GUID to construct, so maybe not...

=cut

has 'token';

=head1 METHODS

=head2 init

Called by L<Telegram::Bot::Brain> to set up the bot.

=cut

sub init {
    my $self = shift;
    $self->add_listener( \&_dispatch );
}

=head1 INTERNAL METHODS

=head2 _dispatch

This is the listener that processes all messages and dispatches them out to the 
methods below for handling.

=cut

sub _dispatch {
    my $self = shift;
    my $update = shift;

    return unless defined $update;



    my $ign_pattern = qr|([A-Za-z0-9]{1,15})|;

    # handle the inline messages

    if ( $update->isa('Telegram::Bot::Object::InlineQuery') ) {

        my $q = $update->query;

        return unless $q =~ m|^\s*(${ign_pattern})\s*$|;

        my $url = $self->_profile_link( $1 );
        my $agent = uc($1);

        my $response = {
            type => 'article',
            id => $agent,
            title => "Agent $agent",
            url => $url,
            hide_url => Mojo::JSON->true,
            input_message_content => {
                    message_text => "Agent [$agent]($url)",
                    parse_mode => "MarkdownV2",
                    link_preview_options => {
                        is_disabled => Mojo::JSON->true,
                    },
            },
        };

        return $update->reply(
            [ $response ],
            {
                cache_time => 86400,
            }
        );
    }

    # otherwise it's a regular chat message
    return unless
        $update->isa('Telegram::Bot::Object::Message');

    my $message = $update->text;

    if ( $update->chat->type eq 'private' ) {
        # PM-exclusive behaviours

        if ( $message =~ m|^\s*\@?(${ign_pattern})\s*| ) {
            return $update->reply(
                "Agent " . $self->_profile_link( $1, 'MarkdownV2' ),
                { parse_mode => 'MarkdownV2' }
            );
        }

        if ( $message =~ m|^/start$|i or $message =~ m|^/help$|i ) {
            return $update->reply( "Send me /profile and an agent name, and I'll do my best...");
        }
    } else { 
        # group-exclusive behaviours
        # are there any of these?
    }

    if ( $message =~ m|^/profile\s+\@?(${ign_pattern})\s*|i ) {
        return $update->reply( "Agent " . $self->_profile_link( $1, 'MarkdownV2' ),
            { parse_mode => 'MarkdownV2' } );
    }

    if ( $message =~ m|^/ada$|i ) {
        return $update->reply( "ADA:" . $self->_profile_link( '__ADA__' ) );
    }
    
    if ( $message =~ m|^/jarvis$|i ) {
        return $update->reply( "Jarvis: " . $self->_profile_link( '__JARVIS__' ) );
    }
    
    if ( $message =~ m|^/machina$|i ) {
        return $update->reply( "Machina: " . $self->_profile_link( '__MACHINA__' ) );
    }

    return;

}

=head2 _profile_link

If it looks like an IGN, we process it here and reply.

=cut

sub _profile_link {
    my $self = shift;
    my $agent = uc shift;
    my $markdown_mode = shift // 0;

    return unless $agent;

    my $url = "https://link.ingress.com/agent/$agent";

    if ( $markdown_mode ) {
        return "[$agent]($url)";
    } else {
        return $url;
    }

}

=head2 _easter_eggs

If it looks like anything else, we check against our list of funny responses
and send the appropriate one, or nothing at all.

=cut 

sub _easter_eggs {
    return; # unimplemented stub
}

1;