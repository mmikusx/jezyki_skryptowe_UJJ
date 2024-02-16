#!/bin/bash

print_help() {
    echo ""
    echo "Interaktywny system zarządzania hasłami"
    echo ""
    echo "Sposób użycia:"
    echo "     ./password_manager.sh"
    echo ""
    echo "Opcje:\n"
    echo "     -h, --help    Wyświetla pomoc"
    echo ""
    echo "Funkcjonalności:"
    echo "     - Dodawanie nowych haseł - umożliwia dodanie nowego wpisu z hasłem do zaszyfrowanego pliku."
    echo "     - Wyświetlenie wszystkich zapisanych haseł - prezentuje listę wszystkich zapisanych wpisów w formie tabeli."
    echo "     - Usuwanie istniejących haseł - pozwala na usunięcie wybranego wpisu na podstawie ID."
    echo "     - Zmiana hasła dla konkretnego serwisu/strony - umożliwia edycję hasła dla wybranego wpisu."
    echo "     - Eksportowanie haseł do pliku nieszyfrowanego - pozwala na eksportowanie wszystkich haseł do pliku tekstowego."
    echo "     - Importowanie haseł z pliku nieszyfrowanego - umożliwia zaimportowanie haseł z pliku tekstowego."
    echo ""
    echo "Wymagania:"
    echo "     - Plik passwords.enc znajdować się musi w tym samym katalogu co skrypt główny, jeżeli nie istnieje zostanie automatycznie utworzony."
    echo "     - Przy pierwszym uruchomieniu skryptu wymagane jest ustalenie głównego hasła zabezpieczającego plik z hasłami."
    echo "     - Przy każdym uruchomieniu programu wymagane jest podanie głównego hasła zabezpieczającego plik z hasłami."
    echo ""
}


PASSWORD_FILE="passwords.enc"

encrypt_file() {
    if [[ ! -f passwords.txt ]]; then
        return 1
    fi
    openssl enc -aes-256-cbc -salt -pbkdf2 -iter 10000 -in passwords.txt -out $PASSWORD_FILE -k "$ENCRYPTION_KEY"
    shred -u passwords.txt
}

decrypt_file() {
    if [[ ! -f $PASSWORD_FILE ]]; then
        return 1
    fi
    openssl enc -d -aes-256-cbc -pbkdf2 -iter 10000 -in $PASSWORD_FILE -out passwords.txt -k "$ENCRYPTION_KEY" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Podano złe hasło główne."
        shred -u passwords.txt 2>/dev/null
        return 1
    fi
}

export_passwords() {
    decrypt_file
    echo "Podaj nazwę pliku do którego będą eksportowane hasła:"
    read export_file
    if [[ -z $export_file ]]; then
        echo "Nazwa pliku do którego mają być eksportowane hasła nie może być pusta."
        encrypt_file
        return 1
    fi
    
    if [[ ! "$export_file" =~ \.txt$ ]]; then
        echo "Plik do którego eskportuje się hasła musi być w formacie tekstowym (.txt)"
        encrypt_file
        return 1
    fi
    
    if [[ -e "$export_file" ]]; then
        while true; do
            read -p "Plik o nazwie '$export_file' już istnieje. Czy chcesz go nadpisać? (t/n): " overwrite
            case $overwrite in
                [Tt]* )
                    cp "passwords.txt" "$export_file"
                    encrypt_file
                    echo "Nadpisano plik '$export_file' i eksportowano hasła"
                    return 1;;
                [Nn]* )
                    encrypt_file
                    echo "Anulowano eksportowanie pliku."
                    return 1;;
                * ) echo "Odpowiedz 't' lub 'n'.";;
            esac
        done
    fi

    cp "passwords.txt" "$export_file"
    encrypt_file
    echo "Hasła zostały wyeksportowane do $export_file."
}

import_passwords() {
    echo "Podaj nazwę pliku z którego mają być importowane dane kont (serwis, login, hasło):"
    read import_file
    if [[ -z $import_file ]]; then
        echo "Nazwa pliku z którego mają być importowane hasła nie może być pusta."
        encrypt_file
        return 1
    fi

    if [[ ! "$import_file" =~ \.txt$ ]]; then
        echo "Plik z którego importuje się hasła musi być w formacie tekstowym (.txt)"
        encrypt_file
        return 1
    fi
    
    if [[ ! -e "$PWD/$import_file" ]]; then
        echo "Nie można znaleźć pliku '$import_file' w bieżącym katalogu."
        encrypt_file
        return 1
    fi

    cp "$PWD/$import_file" "passwords.txt"
    encrypt_file
    echo "Hasła zostały zaimportowane z $import_file."
}

prompt_for_encryption_key() {
    echo "Podaj hasło główne szyfrując plik z hasłami:"
    read -s ENCRYPTION_KEY
}

prompt_for_new_encryption_key() {
    echo "Plik został nowo utworzony lub jest pierwszy raz używany, trzeba ustawić nowe hasło"
    echo "główne do zabezpieczenia danych."
    echo "Podaj nowe hasło główne:"
    read -s ENCRYPTION_KEY
}

show_passwords_with_borders() {
    decrypt_file
    if [ ! -s passwords.txt ]; then
        echo ""
        echo "Brak zapisanych haseł."
        encrypt_file
        return 1
    fi
    echo " _______________________________________________________________________________________ "
    echo "| ID | Serwis              | Adres                  | Login           | Hasło           |"
    echo "|----|---------------------|------------------------|-----------------|-----------------|"
    while IFS='|' read -r id service adress login password; do
        printf "| %-2s | %-19s | %-22s | %-15s | %-15s |\n" "$id" "$service" "$adress" "$login" "$password"
    done < passwords.txt
    echo "|_______________________________________________________________________________________|"
    echo
    encrypt_file
}

add_password() {
    decrypt_file
    echo "Podaj nazwę własną serwisu, dla którego chcesz dodać hasło:"
    read service
    echo "Podaj adres serwisu:"
    read address

    if [[ -z $service && -z $address ]]; then
        echo "Musisz podać przynajmniej jedną informację: nazwę własną serwisu lub adres."
        encrypt_file
        return 1
    fi

    if [[ -z $service ]]; then
        if ! [[ $address =~ ^[a-zA-Z0-9.-]+\.(pl|org|com|eu)$ ]]; then
            echo "Adres serwisu jest w nieprawidłowym formacie (musi mieć kropkę i końcówkę (pl, com, org lub eu))."
            encrypt_file
            return 1
        fi
    elif ! [[ -z $service ]]; then
        if ! [[ -z $address ]]; then
            if ! [[ $address =~ ^[a-zA-Z0-9.-]+\.(pl|org|com|eu)$ ]]; then
                echo "Adres serwisu jest w nieprawidłowym formacie (musi mieć kropkę i końcówkę (pl, com, org lub eu))."
                encrypt_file
                return 1
            fi
        fi
    fi

    if [[ -z $service ]]; then
        service="Nie wprowadzono"
    elif [[ -z $address ]]; then
        address="Nie wprowadzono"
    fi

    echo "Podaj login:"
    read username

    if grep -q "^$service | $username |" passwords.txt || grep -q "^$address | $username |" passwords.txt; then
        echo "Konto o podanym loginie już istnieje dla podanego serwisu lub adresu."
        encrypt_file
        return 1
    fi

    echo "Podaj hasło:"
    read password

    if [[ -z $username || -z $password ]]; then
        echo "Wszystkie pola muszą być wypełnione."
        encrypt_file
        return 1
    fi

    new_id=$(( $(awk -F'|' 'END {print $1}' passwords.txt) + 1 ))
    echo "$new_id | $service | $address | $username | $password" >> passwords.txt
    encrypt_file
    echo "Hasło zostało dodane."
}

delete_password() {
    decrypt_file
    echo "Podaj ID wpisu serwisu lub adresu, który chcesz usunąć:"
    read id_to_delete

    if [[ -z $id_to_delete ]]; then
        echo "ID nie może być puste."
        encrypt_file
        return 1
    fi

    if ! grep -qE "^$id_to_delete \| " passwords.txt; then
        echo "Brak wpisu o podanym ID: $id_to_delete"
        encrypt_file
        return 1
    fi

    grep -v "^$id_to_delete |" passwords.txt > passwords.tmp
    mv passwords.tmp passwords.txt
    encrypt_file
    echo "Hasło zostało usunięte."
}

edit_password() {
    decrypt_file
    echo "Podaj ID wpisu, w którym chcesz edytować hasło:"
    read id_to_edit

    if [[ -z $id_to_edit ]]; then
        echo "ID nie może być puste."
        encrypt_file
        return 1
    fi

    if ! grep -qE "^$id_to_edit \| " passwords.txt; then
        echo "Brak wpisu o podanym ID: $id_to_edit"
        encrypt_file
        return 1
    fi

    old_entry=$(grep "^$id_to_edit \| " passwords.txt)
    old_service=$(echo "$old_entry" | awk -F'|' -v id="$id_to_edit" '$1 == id {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    old_address=$(echo "$old_entry" | awk -F'|' -v id="$id_to_edit" '$1 == id {print $3}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    old_username=$(echo "$old_entry" | awk -F'|' -v id="$id_to_edit" '$1 == id {print $4}' | sed 's/^[ \t]*//;s/[ \t]*$//')

    echo "Podaj nowe hasło:"
    read new_password

    if [[ -z $new_password ]]; then
        echo "Pole nowego hasła musi być wypełnione."
        encrypt_file
        return 1
    fi


    grep -v "^$id_to_delete |" passwords.txt > passwords.tmp
    mv passwords.tmp passwords.txt

    echo "$id_to_edit | $old_service | $old_address | $old_username | $new_password" >> passwords.txt

    encrypt_file
    echo "Hasło zostało zmienione."
}

interactive_menu() {
    while true; do
        echo "----------------------------------";
        echo "          Menadzer haseł          ";
        echo "----------------------------------";
        echo "1. Dodaj nowe hasło"
        echo "2. Pokaż wszystkie hasła"
        echo "3. Usuń hasło"
        echo "4. Zmień hasło dla serwisu"
        echo "5. Eksportuj hasła do pliku"
        echo "6. Importuj hasła z pliku"
        echo "7. Wyjście"
        echo "----------------------------------";
        read -p "Wybierz opcję [1-7]: " option
        
        case "$option" in
            1)
                add_password
                ;;
            2)
                show_passwords_with_borders
                ;;
            3)
                delete_password
                ;;
            4)
                edit_password
                ;;
            5)
                export_passwords
                ;;
            6)
                import_passwords
                ;;
            7)
                echo "Wychodzenie..."
                exit 0
                ;;
            *)
                echo "Nieznana opcja: $option"
                ;;
        esac
    done
}

check_password() {
    decrypt_file
    if [ $? -ne 0 ]; then
        echo "Podano złe hasło szyfrujące."
        exit 1
    fi
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
fi

if [ -f $PASSWORD_FILE ]; then
    prompt_for_encryption_key
    check_password
else
    prompt_for_new_encryption_key
    touch passwords.txt
    encrypt_file
fi

interactive_menu
