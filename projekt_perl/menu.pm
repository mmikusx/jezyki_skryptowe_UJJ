package menu;

use strict;
use warnings;
use reservations;
use Time::Piece;
use Time::Local;


sub new {
    my ($class, $reservations) = @_;
    my $self = {
        reservations => $reservations
    };
    bless $self, $class;
    return $self;
}

sub show_menu {
    print "---------------------------------------------------\n";
    print "Menu systemu obsługi rezerwacji domkow letniskowych\n";
    print "---------------------------------------------------\n";
    print "1. Dodaj rezerwację\n";
    print "2. Anuluj rezerwację\n";
    print "3. Wyświetlenie szczegółów rezerwacji\n";
    print "4. Sprawdź dostępność\n";
    print "5. Pokaż wszystkie rezerwacje na najblizsze 7 dni\n";
    print "6. Pokaż rezerwacje dla konkretnego domku na najblizsze 30 dni\n";
    print "7. Generuj krótki raport dla wszystkich domków za ostatni rok\n";
    print "8. Generuj krótki raport dla konkretnego domku za ostatni rok\n";
    print "9. Wyjście\n";
    print "Wybierz opcję: ";
}

sub add_reservation {
    my ($self) = @_;
    print "Dodawanie rezerwacji...\n";
    print "Podaj numer domku (w zakresie 1-25): ";
    my $cottage_number = <STDIN>;
    chomp($cottage_number);
    if ($cottage_number < 1 || $cottage_number > 25){
        print "Nie mozna dokonac rezerwacji, nie ma takiego domku w systemie (dostępne domki od numeru 1 do 25).\n";
        return;
    }
    print "Podaj datę rozpoczęcia (RRRR-MM-DD): ";
    my $start_date = <STDIN>;
    chomp($start_date);
    if ($start_date !~ /^\d{4}-\d{2}-\d{2}$/) {
        print "Data musi być w formacie RRRR-MM-DD.\n";
        return;
    }
    print "Podaj liczbę nocy: ";
    my $nights = <STDIN>;
    chomp($nights);
    print "Podaj nazwisko rezerwującego: ";
    my $surname = <STDIN>;
    chomp($surname);
    print "Podaj cenę za noc (PLN): ";
    my $price_per_night = <STDIN>;
    chomp($price_per_night);

    if (!$cottage_number || !$start_date || !$nights || !$surname || !$price_per_night) {
        print "Wszystkie pola muszą być wypełnione.\n";
        return;
    }

    eval {
        my $parsed_date = Time::Piece->strptime($start_date, "%Y-%m-%d");
    };
    if ($@) {
        print "Podana data jest nieprawidłowa.\n";
        return;
    }

    $self->{reservations}->add_reservation($cottage_number, $start_date, $nights, $price_per_night, $surname);
}


sub cancel_reservation {
    my ($self) = @_;
    print "Anulowanie rezerwacji...\n";
    print "Podaj numer domku (w zakresie 1-25): ";
    my $cottage_number = <STDIN>;
    chomp($cottage_number);
    if ($cottage_number < 1 || $cottage_number > 25){
        print "Nie mozna anulować rezerwacji, nie ma takiego domku w systemie (dostępne domki od numeru 1 do 25).\n";
        return;
    }
    print "Podaj datę rozpoczęcia (RRRR-MM-DD): ";
    my $start_date = <STDIN>;
    chomp($start_date);

    if (!$cottage_number || !$start_date) {
        print "Wszystkie pola muszą być wypełnione.\n";
        return;
    }
    if ($start_date !~ /^\d{4}-\d{2}-\d{2}$/) {
        print "Data musi być w formacie RRRR-MM-DD.\n";
        return;
    }

    eval {
        my $parsed_date = Time::Piece->strptime($start_date, "%Y-%m-%d");
    };
    if ($@) {
        print "Podana data jest nieprawidłowa.\n";
        return;
    }
    
    $self->{reservations}->cancel_reservation($cottage_number, $start_date);
}

sub check_availability {
    my ($self) = @_;
    print "Sprawdzanie dostępności...\n";
    print "Podaj numer domku (w zakresie 1-25): ";
    my $cottage_number = <STDIN>;
    chomp($cottage_number);
    if ($cottage_number < 1 || $cottage_number > 25){
        print "Nie mozna sprawdzić dostępności, nie ma takiego domku w systemie (dostępne domki od numeru 1 do 25).\n";
        return;
    }
    print "Podaj datę rozpoczęcia (RRRR-MM-DD): ";
    my $start_date = <STDIN>;
    chomp($start_date);
    if ($start_date !~ /^\d{4}-\d{2}-\d{2}$/) {
        print "Data musi być w formacie RRRR-MM-DD.\n";
        return;
    }
    print "Podaj liczbę nocy: ";
    my $nights = <STDIN>;
    chomp($nights);

    if (!$cottage_number || !$start_date || !$nights) {
        print "Wszystkie pola muszą być wypełnione.\n";
        return;
    }

    eval {
        my $parsed_date = Time::Piece->strptime($start_date, "%Y-%m-%d");
    };
    if ($@) {
        print "Podana data jest nieprawidłowa.\n";
        return;
    }

    $self->{reservations}->check_availability($cottage_number, $start_date, $nights);
}

sub show_all_reservations {
    my ($self) = @_;
    print "Pokazywanie wszystkich rezerwacji na najblizsze 7 dni...\n";
    $self->{reservations}->show_all_reservations();
}

sub show_reservations_for_cottage {
    my ($self) = @_;
    print "Pokazywanie rezerwacji dla konkretnego domku na najblizsze 30 dni...\n";
    print "Podaj numer domku (w zakresie 1-25): ";
    my $cottage_number = <STDIN>;
    chomp($cottage_number);
    if (!$cottage_number) {
        print "Trzeba podać numer domku.\n";
        return;
    }
    if ($cottage_number < 1 || $cottage_number > 25){
        print "Nie mozna wyswietlic rezerwacji na najblizsze 30 dni, nie ma takiego domku w systemie (dostępne domki od numeru 1 do 25).\n";
        return;
    }
    
    $self->{reservations}->show_reservations_for_cottage($cottage_number);
}

sub generate_report_for_all_cottages {
    my ($self) = @_;
    print "Generowanie raportu dla wszystkich domków...\n";
    $self->{reservations}->generate_report_for_all_cottages();
}

sub generate_report_for_cottage {
    my ($self) = @_;
    print "Generowanie raportu dla konkretnego domku...\n";
    print "Podaj numer domku (w zakresie 1-25): ";
    my $cottage_number = <STDIN>;
    chomp($cottage_number);

    if (!$cottage_number) {
        print "Trzeba podać numer domku.\n";
        return;
    }
    if ($cottage_number < 1 || $cottage_number > 25){
        print "Nie mozna wygenerować raportu za ostatni rok, nie ma takiego domku w systemie (dostępne domki od numeru 1 do 25).\n";
        return;
    }
    
    $self->{reservations}->generate_report_for_cottage($cottage_number);
}

sub check_details {
    my ($self) = @_;
    print "Wyświetlanie szczegółów rezerwacji...\n";
    print "Podaj numer domku (w zakresie 1-25): ";
    my $cottage_number = <STDIN>;
    chomp($cottage_number);
    if ($cottage_number < 1 || $cottage_number > 25){
        print "Nie mozna wyswietlic szczegołów rezerwacji, nie ma takiego domku w systemie (dostępne domki od numeru 1 do 25).\n";
        return;
    }
    print "Podaj datę rozpoczęcia (RRRR-MM-DD): ";
    my $start_date = <STDIN>;
    chomp($start_date);

    if (!$cottage_number || !$start_date) {
        print "Wszystkie pola muszą być wypełnione.\n";
        return;
    }
    if ($start_date !~ /^\d{4}-\d{2}-\d{2}$/) {
        print "Data musi być w formacie RRRR-MM-DD.\n";
        return;
    }

    eval {
        my $parsed_date = Time::Piece->strptime($start_date, "%Y-%m-%d");
    };
    if ($@) {
        print "Podana data jest nieprawidłowa.\n";
        return;
    }

    $self->{reservations}->print_details($cottage_number, $start_date);
}

1;
