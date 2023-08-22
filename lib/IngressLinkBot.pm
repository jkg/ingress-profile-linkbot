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
    my $message = $update->text;

    unless ( defined $message ) {
        return;
    }

    my $ign_pattern = qr|([A-Za-z0-9_]{1,15})|;

    if ( $update->chat->type eq 'private' ) {
        # PM-exclusive behaviours
        if ( $message =~ m|^\s*\@?(${ign_pattern})\s*| ) {
            return $update->reply( $self->_profile_link( $1 ) );
        }

        if ( $message =~ m|^/start$|i or $message =~ m|^/help$|i ) {
            return $update->reply( "Send me /profile and an agent name, and I'll do my best...");
        }
    } else { 
        # group-exclusive behaviours
        # are there any of these?
    }

    if ( $message =~ m|^/profile\s+\@?(${ign_pattern})\s*|i ) {
        return $update->reply( $self->_profile_link( $1 ) );
    }

    if ( $message =~ m|^/ada$|i ) {
        return $update->reply( $self->_profile_link( '__ADA__' ) );
    }
    
    if ( $message =~ m|^/jarvis$|i ) {
        return $update->reply( $self->_profile_link( '__JARVIS__' ) );
    }
    
    if ( $message =~ m|^/machina$|i ) {
        return $update->reply( $self->_profile_link( '__MACHINA__' ) );
    }

    return;

}

=head2 _profile_link

If it looks like an IGN, we process it here and reply.

=cut

sub _profile_link {
    my $self = shift;
    my $name = shift;
    if ( $name ) {
        return "Agent " . uc($name) . ": "
            . "https://link.ingress.com/?link="
            . uri_encode ( "https://intel.ingress.com/agent/$name", encode_reserved => 1 );
    } else {
        return "I don't really understand what just happened, sorry";
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