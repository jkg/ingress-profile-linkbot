requires 'Config::JSON';
requires 'Telegram::Bot' => '0.021';
requires 'Try::Tiny';

on 'test' => sub {
    requires 'Test2::Suite';
    requires 'Test2::V0';
};

