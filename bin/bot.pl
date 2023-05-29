#!perl

use strict;
use warnings;
use lib 'lib';

use Config::JSON   ();
use IngressLinkBot ();

my $config = Config::JSON->new('config.json');

IngressLinkBot->new(
    map { $_ => $config->get($_) }
      qw|token|
)->think;

