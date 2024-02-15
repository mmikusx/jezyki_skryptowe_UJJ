package reservations;

use strict;
use warnings;
use Date::Parse;
use Date::Format;
use Time::Piece;

my $ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;

sub new {
    my ($class, $file) = @_;
    my $self = {
        file => $file,
    };
    bless $self, $class;
    return $self;
}

sub read_reservations {
    my ($self) = @_;
    my %reservations;
    if (-e $self->{file}) {
        open(my $fh, '<', $self->{file}) or die "Nie mozna otworzyc $self->{file}: $!";
        while (my $line = <$fh>) {
            chomp $line;
            my ($number, $start, $nights, $price_per_night, $surname) = split /,/, $line;
            push @{$reservations{$number}}, {
                start => $start,
                nights => $nights,
                price_per_night => $price_per_night,
                surname => $surname
            };
        }
        close $fh;
    }
    return \%reservations;
}



sub write_reservations {
    my ($self, $reservations) = @_;
    open(my $fh, '>', $self->{file}) or die "Nie mozna otworzyc $self->{file}: $!";
    foreach my $number (keys %{$reservations}) {
        foreach my $reservation (@{$reservations->{$number}}) {
            print $fh join(',', $number, $reservation->{start}, $reservation->{nights}, $reservation->{price_per_night}, $reservation->{surname}) . "\n";
        }
    }
    close $fh;
}



sub add_reservation {
    my ($self, $number, $start, $nights, $price_per_night, $surname) = @_;
    my $reservations = $self->read_reservations();
    
    if (exists $reservations->{$number}) {
        foreach my $reservation (@{$reservations->{$number}}) {
            if ($self->dates_overlap($start, $nights, $reservation->{start}, $reservation->{nights})) {
                print "Rezerwacja domku, którą próbujesz dodać $number w dacie od $start na $nights nocy nakłada się z aktualnie zarezerwowanymi pobytami\n";
            }
        }
    }

    push @{$reservations->{$number}}, {
        start => $start,
        nights => $nights,
        price_per_night => $price_per_night,
        surname => $surname  
    };
    $self->write_reservations($reservations);
    print "Rezerwacja dodana dla domku $number rozpoczynająca się $start na $nights noc(e) po $price_per_night za noc\n";
}


sub cancel_reservation {
    my ($self, $number, $start) = @_;
    my $reservations = $self->read_reservations();

    if (!exists $reservations->{$number} || !grep { $_->{start} eq $start } @{$reservations->{$number}}) {
        print "Nie ma żadnej rezerwacji dla domku $number rozpoczynającej się $start\n";
        return;
    }
    
    @{$reservations->{$number}} = grep { $_->{start} ne $start } @{$reservations->{$number}};
    $self->write_reservations($reservations);
    print "Rezerwacja anulowana dla domku $number rozpoczynająca się $start\n";
}

sub check_availability {
    my ($self, $number, $start, $nights) = @_;
    my $reservations = $self->read_reservations();
    if (exists $reservations->{$number}) {
        foreach my $reservation (@{$reservations->{$number}}) {
            if ($self->dates_overlap($start, $nights, $reservation->{start}, $reservation->{nights})) {
                print "Domek $number nie jest dostępny od $start na $nights noc(e)\n";
                return;
            }
        }
    }
    print "Domek $number jest dostępny od $start na $nights noc(e)\n";
}

sub dates_overlap {
    my ($self, $start1, $nights1, $start2, $nights2) = @_;
    my $start_ts1 = str2time($start1);
    my $end_ts1 = $start_ts1 + $nights1 * 86400;
    
    my $start_ts2 = str2time($start2);
    my $end_ts2 = $start_ts2 + $nights2 * 86400;

    return !($end_ts1 <= $start_ts2 || $start_ts1 >= $end_ts2);
}

sub show_all_reservations {
    my ($self) = @_;
    my $reservations = $self->read_reservations();
    my $current_ts = time();
    my $seven_days_later_ts = $current_ts + 7 * 86400;

    my $has_any_reservations = 0;

    foreach my $number (sort { int($a) <=> int($b) } keys %{$reservations}) {
        my $has_reservations = 0;
        print "Rezerwacje dla domku $number w ciągu najbliższych 7 dni:\n";
        foreach my $reservation (sort { $a->{start} cmp $b->{start} } @{$reservations->{$number}}) {
            my $start_ts = str2time($reservation->{start});
            if ($start_ts >= $current_ts && $start_ts <= $seven_days_later_ts) {
                print " Początek rezerwacji: $reservation->{start}, Nocy: $reservation->{nights}\n";
                $has_reservations = 1;
                $has_any_reservations = 1;
            }
        }
        print "Brak rezerwacji w ciągu najbliższych 7 dni.\n" unless $has_reservations;
    }

    print "Brak jakichkolwiek rezerwacji w ciągu najbliższych 7 dni.\n" unless $has_any_reservations;
}

sub show_reservations_for_cottage {
    my ($self, $number) = @_;
    my $reservations = $self->read_reservations();
    my $current_ts = time();
    my $thirty_days_later_ts = $current_ts + 30 * 86400;
    my $has_any_reservations = 0;

    if (exists $reservations->{$number} && @{$reservations->{$number}} > 0) {
        my @upcoming_reservations = grep {
            my $start_ts = str2time($_->{start});
            $start_ts >= $current_ts && $start_ts <= $thirty_days_later_ts
        } @{$reservations->{$number}};

        if (@upcoming_reservations) {
            print "Rezerwacje dla domku $number w ciągu najbliższych 30 dni:\n";
            foreach my $reservation (sort { $a->{start} cmp $b->{start} } @upcoming_reservations) {
                print " Początek rezerwacji: $reservation->{start}, Nocy: $reservation->{nights}\n";
                $has_any_reservations = 1;
            }
        }
    }
    
    unless ($has_any_reservations) {
        print "Nie znaleziono zadnych rezerwacji dla domku $number w najbliższych 30 dniach.\n";
    }
}


sub generate_report_for_all_cottages {
    my ($self) = @_;
    my $reservations = $self->read_reservations();
    my $current_time = time;
    my $one_year_ago = $current_time - (365 * 24 * 60 * 60);

    my $has_any_past_reservations = 0;
    my $total_income_all_cottages = 0;

    foreach my $number (keys %{$reservations}) {
        my $total_income_for_cottage = 0;
        my $days_reserved_for_cottage = 0;
        my $reservations_count = 0;

        foreach my $reservation (@{$reservations->{$number}}) {
            my $start_ts = str2time($reservation->{start});
            if ($start_ts <= $current_time && $start_ts > $one_year_ago) {
                $has_any_past_reservations = 1;
                $total_income_for_cottage += $reservation->{price_per_night} * $reservation->{nights};
                $days_reserved_for_cottage += $reservation->{nights};
                $reservations_count++;
            }
        }

        if ($reservations_count > 0) {
            my $average_length = $days_reserved_for_cottage / $reservations_count;
            print "Domek $number:\n";
            print "  Ilość zarezerwowanych dni: $days_reserved_for_cottage\n";
            print "  Średnia długość rezerwacji: $average_length dni\n";
            print "  Łączny dochód: $total_income_for_cottage PLN\n";
            $total_income_all_cottages += $total_income_for_cottage;
        }
    }

    if ($has_any_past_reservations) {
        print "\nŁączny dochód ze wszystkich domków: $total_income_all_cottages PLN\n";
    } else {
        print "Brak jakichkolwiek rezerwacji domków w ostatnim roku.\n";
    }
}

sub generate_report_for_cottage {
    my ($self, $number) = @_;
    my $reservations = $self->read_reservations();
    my $current_time = time;
    my $one_year_ago = $current_time - (365 * 24 * 60 * 60);

    my $total_income_for_cottage = 0;
    my $days_reserved_for_cottage = 0;
    my $reservations_count = 0;

    if (exists $reservations->{$number}) {
        foreach my $reservation (@{$reservations->{$number}}) {
            my $start_ts = str2time($reservation->{start});
            if ($start_ts <= $current_time && $start_ts > $one_year_ago) {
                $total_income_for_cottage += $reservation->{price_per_night} * $reservation->{nights};
                $days_reserved_for_cottage += $reservation->{nights};
                $reservations_count++;
            }
        }

        if ($reservations_count > 0) {
            my $average_length = $days_reserved_for_cottage / $reservations_count;
            print "Domek $number:\n";
            print "  Ilość zarezerwowanych dni: $days_reserved_for_cottage\n";
            print "  Średnia długość rezerwacji: $average_length dni\n";
            print "  Łączny dochód: $total_income_for_cottage PLN\n";
        } else {
            print "Nie znaleziono żadnych rezerwacji dla domku $number w ostatnim roku aby wygenerować raport.\n";
        }
    } else {
        print "Nie znaleziono żadnych rezerwacji dla domku $number w ostatnim roku aby wygenerować raport.\n";
    }
}

sub generate_cottage_report {
    my ($self, $reservations) = @_;
    my $total_nights = 0;
    my $total_income = 0;
    my $reservation_count = 0;

    my $current_date = localtime;
    my $one_year_ago = $current_date - $ONE_YEAR_IN_SECONDS;

    foreach my $reservation (@$reservations) {
        my $reservation_date = Time::Piece->strptime($reservation->{start}, "%Y-%m-%d");
        if ($reservation_date > $one_year_ago) {
            if ($reservation_date < $current_date) {
                $total_nights += $reservation->{nights};
                $total_income += $reservation->{nights} * $reservation->{price_per_night};
                $reservation_count++;
            }
        }
    }

    my $average_length = $reservation_count > 0 ? $total_nights / $reservation_count : 0;

    return {
        days_reserved => $total_nights,
        average_length => sprintf("%.2f", $average_length),
        total_income => sprintf("%.2f", $total_income),
    };
}

sub print_details {
    my ($self, $cottage_number, $date) = @_;
    
    my $reservations = $self->read_reservations();
    my $date_obj = Time::Piece->strptime($date, "%Y-%m-%d");

    my $details_found = 0;
    foreach my $reservation (@{$reservations->{$cottage_number}}) {
        my $start_date_obj = Time::Piece->strptime($reservation->{start}, "%Y-%m-%d");
        my $end_date_obj = $start_date_obj + ($reservation->{nights} * 86400);
        
        if ($date_obj >= $start_date_obj && $date_obj < $end_date_obj) {
            my $end_date = $end_date_obj->ymd;
            my $total_price = $reservation->{nights} * $reservation->{price_per_night};
            print "Szczegóły rezerwacji:\n";
            print "     Numer domku: $cottage_number\n";
            print "     Początek rezerwacji: " . $reservation->{start} . "\n";
            print "     Koniec rezerwacji: $end_date\n";
            print "     Ilość nocy: " . $reservation->{nights} . "\n";
            print "     Kwota do zapłaty: $total_price\n";
            print "     Nazwisko rezerwującego: " . $reservation->{surname} . "\n";
            $details_found = 1;
        }
    }

    if (!$details_found) {
        print "Brak rezerwacji na podaną datę dla domku numer $cottage_number\n";
    }
}


1;