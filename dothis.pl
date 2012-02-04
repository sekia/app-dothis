#!/usr/bin/env perl

use 5.014;
use strict;
use warnings;
use AnyEvent;
use Attribute::Constant;
use Cocoa::Growl qw/:all/;
use POSIX qw/:signal_h/;

# die "Growl cannot be detected\n" unless growl_installed;
die "Growl is not running\n" unless growl_running;

my $APP_NAME : Constant('dothis');
my %NOTIFICATIONS : Constant(
  DONE_SUCCESSFULLY => 'Done Successfully',
  ERROR_OCCURED => 'Error Occured',
  INTERRUPTED => 'Interrupted',
);

growl_register(
  app => $APP_NAME,
  notifications => [ values %NOTIFICATIONS ],
);

sub escape_command_line {
  my $arg = shift;
  if (index($arg, ' ') != -1) {
    $arg =~ s/'/\\'/g;
    return qq/'$arg'/;
  }
  return $arg;
}

sub dothis {
  my ($cmd, @args) = @_;
  my $command_line = join ' ', map { escape_command_line $_ } ($cmd, @args);
  my $cv = AE::cv;

  my $pid = fork;
  die 'Forking failed\n' unless defined $pid;

  if ($pid) {  # parent
    my @watchers;
    push @watchers, AE::child $pid => sub {
      my (undef, $status) = @_;
      undef @watchers;
      my $result = $NOTIFICATIONS{
        $status == 0 ? 'DONE_SUCCESSFULLY' : 'ERROR_OCCURED' };
      $cv->send($result);
    };
    push @watchers, AE::signal 'INT' => sub {
      undef @watchers;
      $cv->send($NOTIFICATIONS{INTERRUPTED});
    };

    my $result = $cv->recv;
    growl_notify(
      name => $result,
      title => $result,
      description => $command_line,
    );
  } else {  # child
    exec $cmd, @args or exit -1;
  }
}

dothis @ARGV;
