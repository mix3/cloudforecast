package CloudForecast::Component::MySQL;

use CloudForecast::Component -connector;
use DBI;

sub connection {
    my $self = shift;

    my $dsn = "DBI:mysql:;hostname=".$self->address;
    if ( $self->config->{port} ) {
        $dsn .= ';port='.$self->config->{port}
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

sub is5 {
    my $self = shift;
    my $server_version = $self->connection->get_info(18); # SQL_DBMS_VER
    return  ($server_version =~ /^5/) ? 1 : 0;
}

sub select_row {
    my $self = shift;
    my $query = shift;
    my @param = shift;
    my $row = $self->connection->selectrow_arrayref(
        $query,
        undef,
        @param
    );
    return unless $row;
    return $row->[0];
}

sub select_row {
    my $self = shift;
    my $query = shift;
    my @param = shift;
    my $row = $self->connection->selectrow_hashref(
        $query,
        undef,
        @param
    );
    return $row;
}

sub select_all {
    my $query = shift;
    my @param = shift;
    my $rows = $self->connection->selectall_arrayref(
        $query,
        { Slice => {} },
        @param
    );
    return $rows;
}

1;

