package IngressLinkBot::SafeBrain;

=head1 NAME

IngressLinkBot::SafeBrain - because Telegram::Bot::Brain has a safety issue...

=cut

use Mojo::Base 'Telegram::Bot::Brain';
use Data::Dumper;

=head2 _process_messsage 

Override the Telegram::Bot::Brain version of this sub, to warn rather than dying 
in specific error situations (which TBB does in almost all *other* error conditions,
already...)

=cut 

sub _process_message {
    my $self = shift;
    my $item = shift;

    my $update_id = $item->{update_id};
    # There can be several types of responses. But only one response.
    # https://core.telegram.org/bots/api#update
    my $update;
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{message}, $self)             if $item->{message};
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{edited_message}, $self)      if $item->{edited_message};
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{channel_post}, $self)        if $item->{channel_post};
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{edited_channel_post}, $self) if $item->{edited_channel_post};

    # if we got to this point without creating a response, it must be a type we
    # don't handle yet
    if (! $update) {
      warn "Do not know how to handle this update: " . Dumper($item);
      return;
    }

    foreach my $listener (@{ $self->listeners }) {
      # call the listener code, supplying ourself and the update
      $listener->($self, $update);
    }
}

1;