use inc::Module::Install;
name 'App-DoThis';
all_from 'lib/App/DoThis.pm';

requires 'AnyEvent' => '6.14';
requires 'Attribute::Constant' => '0.02';
requires 'Cocoa::Growl' => '0.05';
requires 'Exporter::Lite' => '0.02';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;

install_script 'dothis';

WriteAll;
