package CloudForecast::Component::AlertMail;

use CloudForecast::Component -connector;

use Path::Class;
use Cache::File;
use Mail::Sendmail;
use Encode;
use utf8;

sub alert_die_update {
    my ( $self, $subject, $alert ) = @_;

    my $c = Cache::File->new(
        cache_root      => '/tmp/alert_cache',
        namespace       => 'AlertMailCache',
        default_expires => '600 sec'
    ) or die "$!";

    my $is_alert = $c->get($subject) || 0;
    my $next = $alert ? $is_alert + $alert : 0;
    $c->set($subject, $next);

    return $is_alert;
}

sub alert_die_send {
    my ( $self, $alert ) = @_;
    
    my @pkg = split(/::/, ref($self));
    my $subject = $pkg[$#pkg] . $self->str_subject("die");
    my $is_alert = $self->alert_die_update($subject, $alert);

    $alert    = $is_alert > 4 ? $alert : 0;
    $is_alert = $is_alert > 5 ?      1 : 0;
    return if($alert == $is_alert);

    CloudForecast::Log->debug("start send alert die mail");

    my $body = $alert ? "もしかして：　死んでる" : "もしかして：　復活";
    $self->send_mail($subject, $body);
}

sub alert_update {
    my ( $self, $subject, $alert ) = @_;

    my $c = Cache::File->new(
        cache_root      => '/tmp/alert_cache',
        namespace       => 'AlertMailCache',
        default_expires => '600 sec'
    ) or die "$!";

    my $is_alert = $c->get($subject) || 0;
    $c->set($subject, $alert);

    return $is_alert;
}

sub alert_sub_send {
    my ($self, $subject, $alert) = @_;

    my $is_alert = $self->alert_update($subject, $alert);
    return if($is_alert == $alert);
    
    CloudForecast::Log->debug("start send alert mail");
    
    my $body = $alert ? "閾値を超えました。ヤバいです。" : "閾値を下回りました。もう大丈夫です。";
    $self->send_mail($subject, $body);
}

sub alert_send {
    my ($self, $alert) = @_;

    while( my ($k, $v) = each(%$alert) ){
        $self->alert_sub_send($k, $v);
    }
}

sub str_subject {
    my $self = shift;
    my $suffix = shift || "";
    my %info;
    $info{ad} = $self->address;
    $info{h}  = $self->hostname;
    $info{as} = join ":", @{$self->args} if @{$self->args};
    return ( keys %info ) ? join(",", map { "$_:$info{$_}" } keys %info) . " " : $suffix;
}

sub send_mail {
    my ($self, $subject, $body) = @_;
    $subject = encode("MIME-Header-ISO_2022_JP", $subject);
    $body    = encode("iso-2022-jp", $body);

    my %mail = (
        "Content-Type" => 'text/plain; charset="iso-2022-jp"',
        To             => join(', ', @{$self->config->{to}}),
        From           => $self->config->{from},
        Subject        => $subject,
        Message        => $body,
    );

    sendmail(%mail);
}

1;
