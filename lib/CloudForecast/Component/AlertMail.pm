package CloudForecast::Component::AlertMail;

use CloudForecast::Component -connector;

use Path::Class;
use DBI;
use Mail::Sendmail;
use Encode;
use utf8;

sub db_path {
    my $self = shift;
    my $data_dir = $self->{config}->{data_dir} || 'data';
    my $db_name  = $self->{config}->{db_name}  || 'alert.db';
    return Path::Class::file($data_dir, $db_name)->cleanup;
}

sub connection {
    my $self = shift;
    return $self->{_connection} if $self->{_connection};
    my $db_path = $self->db_path;

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$db_path","","",
                            { RaiseError => 1, AutoCommit => 1 } );
    $dbh->do(<<EOF);
CREATE TABLE IF NOT EXISTS alert (
    subject VARCHAR(255) NOT NULL,
    is_alert UNSIGNED INT NOT NULL DEFAULT 0,
    PRIMARY KEY ( subject )
)
EOF

    $dbh;
}

sub update {
    my $self = shift;
    my ( $subject, $alert ) = @_;
    my $dbh = $self->connection;
    my $sth = $dbh->prepare(<<EOF);
SELECT * FROM alert WHERE subject = ?
EOF
    $sth->execute($subject);
    my $row = $sth->fetchrow_hashref;

    $sth = $dbh->prepare(<<EOF);
INSERT or Replace INTO alert (subject, is_alert) VALUES (?, ?)
EOF
    $sth->execute($subject, $alert);
    return $row->{is_alert} || 0;
}

sub send {
    my $self = shift;
    my ($subject, $alert) = @_;

    my $is_alert = $self->update($subject, $alert);
    return if($is_alert == $alert);
    
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

1;
