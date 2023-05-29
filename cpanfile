requires 'Config::JSON';
requires 'Telegram::Bot' => '0.021';
requires 'Try::Tiny';
requires 'URI::Encode';

on 'test' => sub {
    requires 'Test2::Suite';
    requires 'Test2::V0';
};

