#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Sub::Wrapper qw(wrap_sub);
use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

my ($sub, $meta);

# return status code s and message m
$sub = sub {
    my %args=@_;
    return [$args{s}, $args{m} // "default message"];
};
$meta = {v=>1.1, args=>{s=>{}, m=>{}}};

test_wrap(
    name        => 'no dies_on_error',
    wrap_args   => {sub => $sub, meta => $meta,
                    convert=>{}},
    wrap_status => 200,
    call_argsr  => [s=>404],
    call_status => 404,
);

test_wrap(
    name        => 'success',
    wrap_args   => {sub => $sub, meta => $meta,
                    convert=>{dies_on_error=>1}},
    wrap_status => 200,
    call_argsr  => [s=>404],
    call_argsr  => [s=>200],
    call_status => 200,
);

test_wrap(
    name        => 'dies',
    wrap_args   => {sub => $sub, meta => $meta,
                    convert=>{dies_on_error=>1}},
    wrap_status => 200,
    call_argsr  => [s=>404],
    call_dies   => 1,
);

test_wrap(
    name        => 'success_statuses #1',
    wrap_args   => {sub => $sub, meta => $meta,
                    convert=>{dies_on_error=>{success_statuses=>qr/^404$/}}},
    wrap_status => 200,
    call_argsr  => [s=>404],
    call_status => 404,
);

test_wrap(
    name        => 'success_statuses #2',
    wrap_args   => {sub => $sub, meta => $meta, debug=>1,
                    convert=>{dies_on_error=>{success_statuses=>qr/^404$/}}},
    wrap_status => 200,
    call_argsr  => [s=>200],
    call_dies   => 1,
);

test_wrap(
    name        =>
        'with result_naked=1, die message still shows status+message #1',
    wrap_args   => {sub => $sub, meta => $meta, debug=>1,
                    convert=>{result_naked=>1, dies_on_error=>1}},
    wrap_status => 200,
    call_argsr  => [s=>411, m=>'foo'],
    call_dies   => 1,
    call_die_message => qr/411.+foo/,
);

done_testing();
