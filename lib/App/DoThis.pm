package App::DoThis;

use 5.014;
use strict;
use warnings;
use AnyEvent;
use Attribute::Constant;
use Cocoa::Growl qw/:all/;
use Exporter::Lite;

our $VERSION = '0.01';
our @EXPORT = qw/dothis
                 growl_installed
                 growl_running
                 register_application/;

my %NOTIFICATIONS : Constant(
  DONE_SUCCESSFULLY => 'Done Successfully',
  ERROR_OCCURED => 'Error Occured',
  INTERRUPTED => 'Interrupted',
);

sub register_application {
  my $app_name = shift;
  growl_register(
    app => $app_name,
    notifications => [ values %NOTIFICATIONS ],
  );
}

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

1;
__END__

=head1 NAME

App::DoThis - Notify via Growl when a command is done

=head1 SYNOPSIS

  use App::DoThis;

=head1 DESCRIPTION

App::DoThis is a command line utility that excutes a command and notify its termination via Growl.

=head1 AUTHOR

Koichi SATOH E<lt>sekia@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
