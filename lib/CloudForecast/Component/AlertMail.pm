package CloudForecast::Component::AlertMail;

use CloudForecast::Component -connector;

use Path::Class;
use Cache::Memory;
use Mail::Sendmail;
use Encode;
use utf8;

sub update {
    my ( $self, $subject, $alert ) = @_;

    my $c = Cache::Memory->new(
        namespace       => 'AlertMailCache',
        default_expires => '600 sec'
    ) or die "$!";

    my $is_alert = $c->get($alert) || 0;
    $c->set($subject, $alert);

    return $is_alert;
}

sub sub_send {
    my $self = shift;
    my ($subject, $alert) = @_;

    my $is_alert = $self->update($subject, $alert);
    return if($is_alert == $alert);
    
    CloudForecast::Log->debug("start send alert mail");
    
    my $body = $alert ? "閾値を超えました。ヤバいです。" : "閾値を下回りました。もう大丈夫です。";
    
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

sub send {
    my ($self, $alert) = @_;

    while( my ($k, $v) = each(%$alert) ){
        $self->sub_send($k, $v);
    }
}

1;
