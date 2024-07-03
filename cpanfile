requires 'Config::JSON';
requires 'Telegram::Bot' => '0.025';
requires 'Try::Tiny';
requires 'URI::Encode';

on 'test' => sub {
    requires 'Test2::Suite';
    requires 'Test2::V0';
};

