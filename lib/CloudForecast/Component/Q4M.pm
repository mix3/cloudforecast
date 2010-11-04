package CloudForecast::Component::Q4M;

use CloudForecast::Component -connector;
use DBI;

sub database {
    my $self = shift;
    $self->args->[0] || die "empty database name";
}

sub table {
    my $self = shift;
    $self->args->[1] || "empty table name";
}

sub port {
    my $self = shift;
    $self->args->[2] || $self->config->{port} || 3306;
}

sub connection {
    my $self = shift;

    my $dsn = "DBI:mysql:".$self->database.";hostname=".$self->address;
    
    if ( my $port = $self->port ) {
        $dsn .= ';port='.$port
    }

    eval {
        $self->{connection} ||= DBI->connect(
            $dsn,
            $self->config->{user} || 'root',
            $self->config->{password} || '',
            {
                RaiseError => 1,
            }
        );
    };
    die "connection failed to " . $self->address .": $@" if $@;

    $self->{connection};
}

sub count {
    my $self = shift;
    $self->connection->selectrow_arrayref("select count(*) from ".$self->table)->[0];
}
 
1;
