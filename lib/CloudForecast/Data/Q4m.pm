package CloudForecast::Data::Q4m;

use CloudForecast::Data -base;
use utf8;

rrds map { [ $_, 'GAUGE' ] } qw/count/;
graphs 'count' => 'Q4M WaitTask Count';

title {
    my $c = shift;
    my $title='Q4M';
    if ( my $table = $c->component('Q4M')->table ) {
        $title .= " (queue_name=$table)";
    }
    return $title;
};

sysinfo {
    my $c = shift;
    $c->ledge_get('sysinfo') || [];
};

fetcher {
    my $c = shift;
    my $q4m = $c->component('Q4M');
    my $result = $q4m->count;

    my $subject = '【ALERT】Q4M/'.$q4m->table;
    my $alert = $result > 20 ? 1 : 0;
    $c->component('AlertMail')->send($subject, $alert);
    
    return [$result];
};

__DATA__
@@ count
DEF:my1=<%RRD%>:count:AVERAGE
AREA:my1#c0c0c0:Count
GPRINT:my1:LAST:Cur\: %4.1lf
GPRINT:my1:AVERAGE:Ave\: %4.1lf
GPRINT:my1:MAX:Max\: %4.1lf
