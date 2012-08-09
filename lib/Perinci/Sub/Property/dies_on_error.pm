package Perinci::Sub::Property::dies_on_error;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Perinci::Util qw(declare_property);

# VERSION

declare_property(
    name => 'dies_on_error',
    type => 'function',
    schema => ['any*' => {of=>[
        ['bool' => {default=>0}],
        ['hash*' => {keys=>{
            'success_statuses'   => ['regex' => {default=>'^(2..|304)$'}],
        }}],
    ]}],
    wrapper => {
        meta => {
            v       => 2,
            prio    => 99, # very low, need to be the last to do stuff to $res
            convert => 1,
            tags    => [qw/die/], # this property can cause function to die
        },
        handler => sub {
            my ($self, %args) = @_;
            my $v    = $args{new} // $args{value} // 0;
            my $meta = $args{meta};

            return unless $v;
            $v = {} if ref($v) ne 'HASH';

            $v->{success_statuses} //= qr/^(2..|304)$/;

            for my $k (qw/success_statuses/) {
                if (defined($v->{$k}) && ref($v->{$k}) ne 'Regexp') {
                    $v->{$k} = qr/$v->{$k}/;
                }
            }

            $self->select_section('before_return_res');
            $self->push_lines('if ($res->[0] !~ /'.$v->{success_statuses}.'/) {');
            $self->indent;
            $self->push_lines(join(
                "",
                'die "Call to ',
                ($self->{_args}{sub_name} ? "$self->{_args}{sub_name}()" : "function"),
                ' returned non-success status $res->[0]: $res->[1]"'));
            $self->unindent;
            $self->push_lines('}');
        },
    },
);

1;
# ABSTRACT: Die on non-success result

=head1 SYNOPSIS

Without dies_on_error:

 # on successful call
 f(...); # [200, "OK"]

 # on non-successful call
 f(...); # [404, "Not found"]

With dies_on_error=>1:

 # on successful call
 f(...); # [200, "OK"]

 # on non-successful call
 f(...); # dies with message "Call f() failed with 404 status: Not found"


=head1 DESCRIPTION

This property sets so that function dies when result status is a non-successful
one (it even dies under wrapping option trap=>1). Successful statuses by default
include 2xx and 304.


=head1 SEE ALSO

L<Perinci>

=cut
