package Ryu::Buffer;

use strict;
use warnings;

our $VERSION = '2.000'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(Ryu::Node);

=encoding utf8

=head1 NAME

Ryu::Buffer - accumulate data

=head1 DESCRIPTION

Provides a simple way to push bytes or characters into a buffer,
and get them back out again.

Typically of use for delimiter-based or fixed-size protocols.

=cut

use curry;
use List::Util qw(min max);

=head1 METHODS

=cut

=head2 new

Instantiates a new, empty L<Ryu::Buffer>.

=cut

sub new {
    my ($class, %args) = @_;
    $args{data} //= '';
    $args{ops} //= [];
    my $self = $class->next::method(%args);
    return $self;
}

=head1 METHODS - Reading data

These methods provide ways of accessing the buffer either
destructively (C<read*>) or non-destructively (C<peek*>).

=cut

=head2 read_exactly

Reads exactly the given number of bytes or characters.

Takes the following parameters:

=over 4

=item * C<$size> - number of characters or bytes to return

=back

Returns a L<Future> which will resolve to a scalar containing the requested data.

=cut

sub read_exactly {
    my ($self, $size) = @_;
    my $f = $self->new_future;
    push @{$self->{ops}}, $self->$curry::weak(sub {
        my ($self) = @_;
        return $f if $f->is_ready;
        return $f unless $size <= length($self->{data});
        $f->done(substr($self->{data}, 0, $size, ''));
    });
    $self->process_pending;
    $f;
}

=head2 read_atmost

Reads up to the given number of bytes or characters - if
we have at least one byte or character in the buffer, we'll
return that even if it's shorter than the requested C<$size>.
This method is guaranteed not to return B<more> than the
C<$size>.

Takes the following parameters:

=over 4

=item * C<$size> - maximum number of characters or bytes to return

=back

Returns a L<Future> which will resolve to a scalar containing the requested data.

=cut

sub read_atmost {
    my ($self, $size) = @_;
    my $f = $self->new_future;
    push @{$self->{ops}}, $self->$curry::weak(sub {
        my ($self) = @_;
        return $f if $f->is_ready;
        return $f unless length($self->{data});
        $f->done(substr($self->{data}, 0, min($size, length($self->{data})), ''));
    });
    $self->process_pending;
    $f;
}

=head2 read_atleast

Reads at least the given number of bytes or characters - if
we have a buffer that's the given size or larger, we'll
return everything available, even if it's larger than the
requested C<$size>.

Takes the following parameters:

=over 4

=item * C<$size> - minimum number of characters or bytes to return

=back

Returns a L<Future> which will resolve to a scalar containing the requested data.

=cut

sub read_atleast {
    my ($self, $size) = @_;
    my $f = $self->new_future;
    push @{$self->{ops}}, $self->$curry::weak(sub {
        my ($self) = @_;
        return $f if $f->is_ready;
        return $f unless length($self->{data}) >= $size;
        $f->done(substr($self->{data}, 0, max($size, length($self->{data})), ''));
    });
    $self->process_pending;
    $f;
}

=head2 read_until

Reads up to the given string or regex match.

Pass a C<< qr// >> instance if you want to use a regular expression to match,
or a plain string if you want exact-string matching behaviour.

The data returned will B<include> the match.

Takes the following parameters:

=over 4

=item * C<$match> - the string or regex to match against

=back

Returns a L<Future> which will resolve to the requested bytes or characters.

=cut

sub read_until {
    my ($self, $match) = @_;
    $match = qr/\Q$match/ unless ref($match) eq 'Regexp';
    my $f = $self->new_future;
    push @{$self->{ops}}, $self->$curry::weak(sub {
        my ($self) = @_;
        return $f if $f->is_ready;
        return $f unless length($self->{data});
        return $f unless $self->{data} =~ /$match/g;
        $f->done(substr($self->{data}, 0, pos($self->{data}), ''));
    });
    $self->process_pending;
    $f;
}

=head2 write

Add more data to the buffer.

Call this with a single scalar, and the results will be appended
to the internal buffer, triggering any callbacks for read activity
as required.

=cut

sub write {
    my ($self, $data) = @_;
    $self->{data} .= $data;
    $self->process_pending if @{$self->{ops}};
    return $self;
}

=head2 size

Returns the current buffer size.

=cut

sub size { length(shift->{data}) }

=head2 is_empty

Returns true if the buffer is currently empty (size = 0), false otherwise.

=cut

sub is_empty { !length(shift->{data}) }

=head1 METHODS - Internal

These are documented for convenience, but generally not recommended
to call any of these directly.

=head2 data

Accessor for the internal buffer. Not recommended to use this,
but if you break it you get to keep all the pieces.

=cut

sub data { shift->{data} }

=head2 process_pending

Used internally to trigger callbacks once L</write> has been called.

=cut

sub process_pending {
    my ($self) = @_;
    while(1) {
        my ($op) = @{$self->{ops}} or return;
        my $f = $op->();
        return unless $f->is_ready;
        shift @{$self->{ops}};
    }
}

=head2 new_future

Instantiates a new L<Future>, used to ensure we get something awaitable.

Can be overridden using C<$Ryu::FUTURE_FACTORY>.

=cut

sub new_future {
    my $self = shift;
    require Ryu;
    (
        $self->{new_future} //= $Ryu::FUTURE_FACTORY
    )->($self, @_)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.

