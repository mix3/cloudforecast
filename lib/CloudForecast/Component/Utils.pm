package CloudForecast::Component::Utils;

use CloudForecast::Component -connector;

sub str_info {
    my $c = shift;
    my %info;
    $info{ad} = $c->address;
    $info{h}  = $c->hostname;
    $info{as} = join ":", @{$c->args} if @{$c->args};
    my $info  = ( keys %info ) ? join(",", map { "$_:$info{$_}" } keys %info) . " " : "";
    $info =~ s/\s$//;
    return $info;
}

1;
