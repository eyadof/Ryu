package Ryu::Node;

use strict;
use warnings;

# VERSION
# AUTHORITY

=head1 NAME

Ryu::Node - generic node

=head1 DESCRIPTION

This is a common base class for all sources, sinks and other related things.
It does very little.

=cut

use Future;
use Scalar::Util qw(refaddr);

=head1 METHODS

Not really. There's a constructor, but that's not particularly exciting.

=cut

sub new {
    bless {
        pause_propagation => 1,
        @_[1..$#_]
    }, $_[0]
}

=head2 describe

Returns a string describing this node and any parents - typically this will result in a chain
like C<< from->combine_latest->count >>.

=cut

# It'd be nice if L<Future> already provided a method for this, maybe I should suggest it
sub describe {
    my ($self) = @_;
    ($self->parent ? $self->parent->describe . '=>' : '') . $self->label . '(' . $self->completed->state . ')';
}

=head2 pause

Does nothing useful.

=cut

sub pause {
    my ($self, $src) = @_;
    my $k = refaddr($src) // 0;

    my $was_paused = $self->{is_paused} && keys %{$self->{is_paused}};
    unless($was_paused) {
        delete $self->{unblocked} if $self->{unblocked} and $self->{unblocked}->is_ready;
    }
    ++$self->{is_paused}{$k};
    if(my $parent = $self->parent) {
        $parent->pause($self) if $self->{pause_propagation};
    }
    if(my $flow_control = $self->{flow_control}) {
        $flow_control->emit(0) unless $was_paused;
    }
    $self
}

=head2 resume

Is about as much use as L</pause>.

=cut

sub resume {
    my ($self, $src) = @_;
    my $k = refaddr($src) // 0;
    delete $self->{is_paused}{$k} unless --$self->{is_paused}{$k} > 0;
    unless($self->{is_paused} and keys %{$self->{is_paused}}) {
        my $f = $self->unblocked;
        $f->done unless $f->is_ready;
        if(my $parent = $self->parent) {
            $parent->resume($self) if $self->{pause_propagation};
        }
        if(my $flow_control = $self->{flow_control}) {
            $flow_control->emit(1);
        }
    }
    $self
}

=head2 unblocked

Returns a L<Future> representing the current flow control state of this node.

It will be L<pending|Future/is_pending> if this node is currently paused,
otherwise L<ready|Future/is_ready>.

=cut

sub unblocked {
    my ($self) = @_;
    $self->{unblocked} //= do {
        $self->is_paused
        ? $self->{new_future}->()
        : Future->done
    };
}

=head2 is_paused

Might return 1 or 0, but is generally meaningless.

=cut

sub is_paused {
    my ($self, $obj) = @_;
    return keys %{ $self->{is_paused} } ? 1 : 0 unless defined $obj;
    my $k = refaddr($obj);
    return exists $self->{is_paused}{$k}
    ? 0 + $self->{is_paused}{$k}
    : 0;
}

sub flow_control {
    my ($self) = @_;
    $self->{flow_control} //= Ryu::Source->new(
        new_future => $self->{new_future}
    )
}

sub label { shift->{label} }

sub parent { shift->{parent} }

sub new_future { shift->{new_future}->() }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2021. Licensed under the same terms as Perl itself.

