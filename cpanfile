requires 'Config::JSON';
requires 'Telegram::Bot' => '0.021';
requires 'Try::Tiny';
requires 'Log::Dispatch';
requires 'Log::Dispatch::FileRotate';

on 'test' => sub {
    requires 'Test2::Suite';
    requires 'Test2::V0';
};

