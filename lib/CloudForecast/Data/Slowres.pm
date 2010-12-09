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
    $c->ledge_get('sysinfo') || [];
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
    
    my $info = decode_json($response->content);
    my $num = @$info;
    return [$num];
};

basic_alert {
    my $c = shift;

    CloudForecast::Log->debug('Slow Response  basic alert');

    my $address = $c->address;
    my $port = $c->args->[0] || 80;
    my $path = $c->args->[1] || '/';

    my $ua = $c->component('LWP');
    my $req = HTTP::Request->new( GET => "http://${address}:$port$path" );
    my $response = $ua->request($req);
    die "server-status failed: " .$response->status_line
        unless $response->is_success;

    my $info = decode_json($response->content);
    my @arr = @$info;

    my $min5before  = localtime() - 300 - (3600 * 2);
    foreach(@$info){
        my $t = Time::Piece->strptime($_->{date}." +0900", "%Y-%m-%d %H:%M:%S %z");
        shift @arr if($min5before > $t);
    }
    
    my $num = @arr;
    CloudForecast::Log->debug('Slow Response Num (in 5 min): '.$num);
    my $result = {};
    if($num > 20){
        my $info = $c->component('Utils')->str_info;
        my $subject = "[Slow Response $info]";
        $result->{$subject} = 'Slow Response num > 20';
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
