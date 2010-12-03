package CloudForecast::Data::Apc;

use CloudForecast::Data -base;
use JSON;

rrds map { [$_,'GAUGE'] } qw/used free fhits fmisses uhits umisses/;

graphs 'memory' => 'Memory Usage [%]';
graphs 'fhm' => 'File Cache Hits & Misses [%]';
graphs 'uhm' => 'User Cache Hits & Misses [%]';

title {
    my $c = shift;
    return "APC";
};

sysinfo {
    my $c = shift;
    my @sysinfo;
    if ( my $sysinfo = $c->ledge_get('sysinfo') ) {
        push @sysinfo, 'Segment(s)', $sysinfo->{num_seg} if($sysinfo->{num_seg});
        
        if($sysinfo->{seg_size}){
            my $k;
            foreach (('','K','M','G')) {
                $k = $_;
                last if($sysinfo->{seg_size} < 1024);
                $sysinfo->{seg_size} /= 1024;
            }
            push @sysinfo, 'Memory', sprintf("%5.1f %sBytes",$sysinfo->{seg_size}, $k);
        }
        
        if ( my $uptime = $sysinfo->{uptime} ) {
            $uptime = time() - $uptime;
            my $day = int( $uptime /86400 );
            my $hour = int( ( $uptime % 86400 ) / 3600 );
            my $min = int( ( ( $uptime % 86400 ) % 3600) / 60 );
            push @sysinfo, 'uptime', sprintf("up %d days, %2d:%02d", $day, $hour, $min);
        }
        
        map { push @sysinfo, $_, $sysinfo->{$_} } grep { exists $sysinfo->{$_} }
            qw/memory_type locking_type/;
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

    my $info = decode_json($response->content);

    my $mem_size  = $info->{memory}->{num_seg} * $info->{memory}->{seg_size};
    my $mem_avail = $info->{memory}->{avail_mem};
    my $mem_used  = $mem_size - $mem_avail;

    my %sysinfo;
    $sysinfo{uptime} = $info->{file_cache}->{start_time} || 0;
    map { $sysinfo{$_} = $info->{memory}->{$_} } grep { exists $info->{memory}->{$_} }
        qw/num_seg seg_size/;
    map { $sysinfo{$_} = $info->{file_cache}->{$_} } grep { exists $info->{file_cache}->{$_} }
        qw/memory_type locking_type/;
    $c->ledge_set('sysinfo', \%sysinfo );

    return [
        $mem_used,
        $mem_avail,
        $info->{file_cache}->{num_hits},
        $info->{file_cache}->{num_misses},
        $info->{user_cache}->{num_hits},
        $info->{user_cache}->{num_misses}
    ];
};

sub duration{
    my $ts = shift;
    my $time = time();
    
    my $years = int(($time - $ts) / (7 * 86400) / 52.177457);
    my $rem   = int(($time - $ts) - ($years * 52.177457 * 7 * 86400));
    my $weeks = int( $rem / (7 * 86400));
    my $days  = int(($rem / 86400) - ($weeks * 7));
    my $hours = int(($rem / 3600) - ($days * 24) - ($weeks * 7 * 24));
    my $mins  = int(($rem / 60) - ($hours * 60) - ($days * 24 * 60) - ($weeks * 7 * 24 * 60));

    my $str   = '';
    $str .= "$years year, "     if($years == 1);
    $str .= "$years years, "    if($years >  1);
    $str .= "$weeks week, "     if($weeks == 1);
    $str .= "$weeks weeks, "    if($weeks >  1);
    $str .= "$days day,"        if($days  == 1);
    $str .= "$days days,"       if($days  >  1);
    $str .= " $hours hour and"  if($hours == 1);
    $str .= " $hours hours and" if($hours >  1);
    if($mins == 1){
        $str .= " 1 minute";
    }else{
        $str .= " $mins minutes";
    }

    return $str;
}

__DATA__
@@ memory
DEF:my1=<%RRD%>:used:AVERAGE
DEF:my2=<%RRD%>:free:AVERAGE

CDEF:total=my1,my2,+
CDEF:my1r=my1,total,/,100,*,0,100,LIMIT
CDEF:my2r=my2,total,/,100,*,0,100,LIMIT

AREA:my1r#008080:Used
GPRINT:my1r:LAST:Cur\: %4.1lf[%%]
GPRINT:my1r:AVERAGE:Ave\: %4.1lf[%%]
GPRINT:my1r:MAX:Max\: %4.1lf[%%]
GPRINT:my1r:MIN:Min\: %4.1lf[%%]\l
STACK:my2r#C0C0C0:Free
GPRINT:my2r:LAST:Cur\: %4.1lf[%%]
GPRINT:my2r:AVERAGE:Ave\: %4.1lf[%%]
GPRINT:my2r:MAX:Max\: %4.1lf[%%]
GPRINT:my2r:MIN:Min\: %4.1lf[%%]\l

@@ fhm
DEF:my1=<%RRD%>:fhits:AVERAGE
DEF:my2=<%RRD%>:fmisses:AVERAGE

CDEF:total=my1,my2,+
CDEF:my1r=my1,total,/,100,*,0,100,LIMIT
CDEF:my2r=my2,total,/,100,*,0,100,LIMIT

AREA:my1r#00C000:Hits
GPRINT:my1r:LAST:Cur\: %4.1lf[%%]
GPRINT:my1r:AVERAGE:Ave\: %4.1lf[%%]
GPRINT:my1r:MAX:Max\: %4.1lf[%%]
GPRINT:my1r:MIN:Min\: %4.1lf[%%]\l
STACK:my2r#0000C0:Misses
GPRINT:my2r:LAST:Cur\: %4.1lf[%%]
GPRINT:my2r:AVERAGE:Ave\: %4.1lf[%%]
GPRINT:my2r:MAX:Max\: %4.1lf[%%]
GPRINT:my2r:MIN:Min\: %4.1lf[%%]\l

@@ uhm
DEF:my1=<%RRD%>:uhits:AVERAGE
DEF:my2=<%RRD%>:umisses:AVERAGE

CDEF:total=my1,my2,+
CDEF:my1r=my1,total,/,100,*,0,100,LIMIT
CDEF:my2r=my2,total,/,100,*,0,100,LIMIT

AREA:my1r#00C000:Hits
GPRINT:my1r:LAST:Cur\: %4.1lf[%%]
GPRINT:my1r:AVERAGE:Ave\: %4.1lf[%%]
GPRINT:my1r:MAX:Max\: %4.1lf[%%]
GPRINT:my1r:MIN:Min\: %4.1lf[%%]\l
STACK:my2r#0000C0:Misses
GPRINT:my2r:LAST:Cur\: %4.1lf[%%]
GPRINT:my2r:AVERAGE:Ave\: %4.1lf[%%]
GPRINT:my2r:MAX:Max\: %4.1lf[%%]
GPRINT:my2r:MIN:Min\: %4.1lf[%%]\l
