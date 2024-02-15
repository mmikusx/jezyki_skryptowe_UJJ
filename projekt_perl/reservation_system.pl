#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use reservations;
use menu;

my $reservations_file = "reservations.txt";
my $reservations = reservations->new($reservations_file);
my $menu = menu->new($reservations);

sub print_help {
    print "\n";
    print "Interaktywny system obsługi rezerwacji domków letniskowych  domków działający w terminalu,\n";
    print "stworzony dla właściciela 25 domków letniskowych, aby pomóc mu w zarządzaniu rezerwacjami.\n";
    print "\n";
    print "Sposób użycia:\n";
    print "     perl $0\n";
    print "\n";
    print "Opcje:\n";
    print "     -h, --help    Wyświetla pomoc\n";
    print "\n";
    print "Funkcjonalności:\n";
    print "     - Dodawanie nowych rezerwacji (którego domku rezerwacja się tyczy, długości\n";
    print "     rezerwacji (daty początkowej oraz liczby nocy), ceny za noc)\n";
    print "     - Anulowanie istniejących rezerwacji\n";
    print "     - Wyświetlenie szczegółów rezerwacji\n";
    print "     - Sprawdzanie dostępności domków w określonym terminie\n";
    print "     - Wyświetlenie wszystkich rezerwacji w najblizszych 7 dniach\n";
    print "     - Wyświetlenie rezerwacje dla konkretnego domku w najblizszych 30 dniach\n";
    print "     - Wygenerowanie krótkiego raportu dla wszystkich domków za ostatni rok\n";
    print "     - Wygenerowanie krótkiego raportu dla konkretnego domku za ostatni rok\n";
    print "\n";
    print "Wymagania:\n";
    print "     Plik reservations.txt znajdować się musi w tym samym katalogu co skrypt główny, jezeli nie istnieje zostanie automatycznie utworzony.\n";
    exit 0;
}

if ( @ARGV && ( $ARGV[0] eq '-h' || $ARGV[0] eq '--help' ) ) {
    print_help();
}


while (1) {
    $menu->show_menu();
    my $choice = <STDIN>;
    chomp($choice);
    
    if ($choice == 1) {
        $menu->add_reservation();
    } elsif ($choice == 2) {
        $menu->cancel_reservation();
    } elsif ($choice == 3) {
        $menu->check_details();
    } elsif ($choice == 4) {
        $menu->check_availability();
    } elsif ($choice == 5) {
        $menu->show_all_reservations();
    } elsif ($choice == 6) {
        $menu->show_reservations_for_cottage();
    } elsif ($choice == 7) {
        $menu->generate_report_for_all_cottages();
    } elsif ($choice == 8) {
        $menu->generate_report_for_cottage();
    } elsif ($choice == 9) {
        print "Wychodzenie z programu...\n";
        last;
    } else {
        print "Nieprawidłowa opcja, spróbuj ponownie.\n";
    }
}

