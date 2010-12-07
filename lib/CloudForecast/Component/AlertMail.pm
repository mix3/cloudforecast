package CloudForecast::Component::AlertMail;

use CloudForecast::Component -connector;

use Mail::Sendmail;
use Encode;
use utf8;

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

sub send {
    my $self    = shift;
    my $subject = shift;
    my $body    = shift || "死んでる？";
    $self->send_mail($subject, $body);
}

1;
