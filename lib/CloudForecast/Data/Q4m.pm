package CloudForecast::Data::Q4m;

use CloudForecast::Data -base;
use utf8;

rrds map { [ $_, 'GAUGE' ] } qw/count/;
graphs 'count' => 'Q4M WaitTask Count';

title {
    my $c = shift;
    return 'Q4M '.$c->component('Utils')->str_info;
};

sysinfo {
    my $c = shift;
    $c->ledge_get('sysinfo') || [];
};

fetcher {
    my $c = shift;
    $c->args->[0] || $c->args->[1] || die "$!";
    my $mysql = $c->component('MySQL');
    my $table = $c->args->[0].'.'.$c->args->[1];
    my $row = $mysql->select_row("select count(*) as count from $table");
    return [$$row{count}];
};

alert_mail {
    my ($c, $ret) = @_;

    my $info = $c->component('Utils')->str_info;
    my $subject = "[Q4M $info]";
    my $alert = !!($ret > 20);
    return {$subject => $alert};
};

__DATA__
@@ count
DEF:my1=<%RRD%>:count:AVERAGE
AREA:my1#c0c0c0:Count
GPRINT:my1:LAST:Cur\: %4.1lf
GPRINT:my1:AVERAGE:Ave\: %4.1lf
GPRINT:my1:MAX:Max\: %4.1lf
