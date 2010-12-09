package CloudForecast::Data::Slowres;

use CloudForecast::Data -base;
use Time::Piece;
use JSON;

rrds 'slow_response' => 'GAUGE';

graphs 'count' => 'Slow Response Num';

title {
    my $c = shift;
    return 'Slow Response';
};

sysinfo {
    my $c = shift;
    my @sysinfo;
    if ( my $sysinfo = $c->ledge_get('sysinfo') ) {
        if($sysinfo->{size}){
            my $k;
            foreach (('','K','M','G')) {
                $k = $_;
                last if($sysinfo->{size} < 1024);
                $sysinfo->{size} /= 1024;
            }
            push @sysinfo, 'LogFile Size', sprintf("%5.1f %sBytes",$sysinfo->{size}, $k);
        }
        push @sysinfo, 'LogFile Line Num', $sysinfo->{line} if($sysinfo->{line});
    }
    return \@sysinfo;
};

fetcher {
    my $c = shift;
    my $address = $c->address;
    my $port = $c->args->[0] || 80;
    my $path = $c->args->[1] || '/';
    
    my $ua = $c->component('LWP');
    my $req = HTTP::Request->new( GET => "http://${address}:$port$path" );
    my $response = $ua->request($req);
    die "server-status failed: " .$response->status_line
        unless $response->is_success;
    
    my $res = decode_json($response->content);

    $c->ledge_set('sysinfo', \%{$res->{'log_bak_info'}});

    my $num = my @info = @{$res->{'log'}};
    
    my $result = 0.0;
    if($num > 0){
        my $t = Time::Piece->strptime($info[0]->{date}." +0900", "%Y-%m-%d %H:%M:%S %z");
        $result = $num / (localtime() - $t) * 60;
    }

    CloudForecast::Log->debug($result.' slow_res / min');
    
    return [$result];
};

basic_alert {
    my $c   = shift;
    my $let = shift;
    
    CloudForecast::Log->debug('Slow Response basic alert');

    my $result = {};

    # slow_res / min > 10
    if($$let[0] > 10){
        my $subject = "[Slow Response ".$c->component('Utils')->str_info."]";
        $result->{$subject} = "slow_res / min > 10";
    }

    return $result;
};

__DATA__
@@ count
DEF:my1=<%RRD%>:slow_response:AVERAGE
AREA:my1#c0c0c0:Count
GPRINT:my1:LAST:Cur\: %4.1lf
GPRINT:my1:AVERAGE:Ave\: %4.1lf
GPRINT:my1:MAX:Max\: %4.1lf
GPRINT:my1:MIN:Min\: %4.1lf\c
