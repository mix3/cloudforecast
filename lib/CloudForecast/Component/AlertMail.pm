package CloudForecast::Component::AlertMail;

use CloudForecast::Component -connector;

use Mail::Sendmail;
use Encode;
use utf8;

sub send_mail {
    my ($self, $subject, $body) = @_;
    $subject = encode("MIME-Header-ISO_2022_JP", decode_utf8($subject));
    $body    = encode("iso-2022-jp", decode_utf8($body));
    my %mail = (
        "Content-Type" => 'text/plain; charset="iso-2022-jp"',
        To             => join(', ', @{$self->config->{to}}),
        From           => $self->config->{from},
        Subject        => $subject,
        Message        => $body,
    );
    sendmail(%mail);
}

sub send_die {
    my $self    = shift;
    my $body    = shift;
    my $subject = $self->config->{title}." Die";
    
    $self->_send($subject, $body);
}

sub send_basic {
    my $self    = shift;
    my $body    = shift;
    my $subject = $self->config->{title}." Basic";
    
    $self->_send($subject, $body);
}

sub _send {
    my $self    = shift;
    my $subject = shift;
    my $body    = shift;
    $self->send_mail($subject, $body);
}

1;
