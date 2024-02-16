#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import random
import sys

class Quiz:
    def __init__(self, questions=None):
        self.questions = questions if questions else []

    def add_question(self, question, options, correct_answer, difficulty):
        self.questions.append({
            "question": question,
            "options": options,
            "correct_answer": correct_answer,
            "difficulty": difficulty
        })
        print("Dodano pytanie do quizu.")

    def remove_question(self, identifier):
        if isinstance(identifier, int):
            if 0 <= identifier < len(self.questions):
                del self.questions[identifier]
                print(f"Usunięto pytanie o indeksie {identifier}.")
            else:
                print("Niepoprawny indeks pytania.")


    def save_to_file(self, filename):
        try:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            data_file_path = os.path.join(script_dir, filename)
            with open(data_file_path, 'w') as file:
                json.dump(self.questions, file)
            print(f"Quiz został zapisany do pliku {filename}.")
        except IOError as e:
            print(f"Błąd przy zapisywaniu do pliku {filename}: {e}")


    def load_from_file(self, filename):
        if not os.path.exists(filename):
            print(f"Nie można otworzyć pliku {filename}, ponieważ nie istnieje.")
            return False
        try:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            data_file_path = os.path.join(script_dir, filename)
            with open(data_file_path, 'r') as file:
                self.questions = json.load(file)
            return True
        except IOError as e:
            print(f"Błąd przy otwieraniu pliku {filename}: {e}")
            return False


    def run_quiz(self):
        incorrect_questions = self.questions.copy()
        attempt = 0
        results = []

        while incorrect_questions:
            score = 0
            total_possible_score = 0
            attempt += 1
            retry_questions = []

            random.shuffle(incorrect_questions)

            for question in incorrect_questions:
                print(question["question"])
                
                options = question["options"]
                correct_answer = question["correct_answer"]
                shuffled_options = options.copy()
                random.shuffle(shuffled_options)
                
                correct_answer_index = shuffled_options.index(correct_answer) + 1
                
                for idx, option in enumerate(shuffled_options, 1):
                    print(f"{idx}. {option}")
                    
                answer = int(input("Twoja odpowiedź (numer): "))
                
                difficulty_points = {"Łatwe": 1, "Średnie": 2, "Trudne": 3}
                question_score = difficulty_points.get(question["difficulty"], 1)
                total_possible_score += question_score
                
                if answer == correct_answer_index:
                    print("Poprawna odpowiedź!")
                    score += question_score
                else:
                    print("Niepoprawna odpowiedź.")
                    retry_questions.append(question)
                print()

            results.append((score, total_possible_score))
            print(f"Wynik za próbę {attempt}: {score}/{total_possible_score} punktów.")

            if not retry_questions:
                break

            incorrect_questions = retry_questions.copy()
            if input("Czy chcesz odpowiedzieć jeszcze raz na pytania, na które nie udzieliłeś dobrej odpowiedzi? (t/n): ").lower() != 't':
                break

        print("\nPodsumowanie:")
        for i, (score, total) in enumerate(results, 1):
            print(f"Próba {i}: {score} na {total} możliwych punktów.")
        print(f"Twój wynik łączny to {sum([score for score, total in results])} na {sum([total for score, total in results])} możliwych punktów.")

def print_help():
    help_text = """
    Generator Quizów - sposoby użycia:
    -h, --help                Pokazuje tę pomoc.
    -f FILE, --file FILE      Określa nazwę pliku do zapisu/odczytu quizu.
    -c, --create              Rozpoczyna proces tworzenia nowego quizu. Wymaga opcji -f. 
                              Jeśli plik już istnieje, sugeruje użycie opcji -e do edycji.
    -r, --run                 Przeprowadza quiz z określonego pliku. Wymaga opcji -f.
    -e, --edit                Edytuje istniejący quiz (dodawanie/usuwanie pytań). 
                              Wymaga opcji -f. Oferuje opcje dodania nowego pytania (d), 
                              usunięcia istniejącego pytania (u) oraz zapisania zmian i wyjścia (z).

    Przykłady użycia:
    Tworzenie nowego quizu:   python quiz_generator.py -c -f myquiz.json
    Przeprowadzanie quizu:    python quiz_generator.py -r -f myquiz.json
    Edycja istniejącego quizu: python quiz_generator.py -e -f myquiz.json

    Wymagania:
    - Program do stworzenia, przeprowadzenia lub edycji quizu potrzebuje pliku quizu w formacie JSON.
    - Pytania w quizie mogą mieć różne poziomy trudności: łatwe, średnie, trudne.
    - Jeśli jest się proszonym o podanie listy odpowiedzi, należy je oddzielić przecinkami bez spacji po przecinku.

    Punktacja:
    Pytania są punktowane w zależności od poziomu trudności:
    - Łatwe: 1 punkt
    - Średnie: 2 punkty
    - Trudne: 3 punkty
    Punktacja ta jest przydzielana za każdą poprawnie udzieloną odpowiedź.
    """
    print(help_text)
    exit()


def parse_args():
    args = {"create": False, "file": None, "run": False, "edit": False}
    argv = sys.argv[1:]

    if "-h" in argv or "--help" in argv:
        print_help()

    if "-c" in argv or "--create" in argv:
        args["create"] = True

    if "-r" in argv or "--run" in argv:
        args["run"] = True

    if "-e" in argv or "--edit" in argv:
        args["edit"] = True

    if "-f" in argv or "--file" in argv:
        file_index = argv.index("-f") + 1
        if file_index < len(argv):
            args['file'] = argv[file_index]
            next_arg = file_index + 1
            if next_arg < len(argv) and not argv[next_arg].startswith("-"):
                print("Po opcji -f powinien być podany dokładnie jeden plik.")
                exit(1)
            if not args['file'].endswith('.json'):
                print("Plik musi być w formacie .json.")
                exit(1)
        else:
            print("Opcja -f wymaga podania nazwy pliku.")
            exit(1)

    return args



def main():
    args = parse_args()

    quiz = Quiz()

    if args["file"]:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        data_file_path = os.path.join(script_dir, args["file"])
        args["file"] = data_file_path

    if args["create"] and args['file']:
        if os.path.exists(args['file']):
            print(f"Plik '{args['file']}' już istnieje. Użyj opcji -e do edycji istniejącego quizu.")
        else:
            while True:
                while True:
                    difficulty = input("Wprowadź poziom trudności pytania (łatwe, średnie, trudne): ").capitalize()
                    if difficulty not in ["Łatwe", "Średnie", "Trudne"]:
                        print("Niepoprawny poziom trudności. Wpisz ponownie.")
                        continue
                    break
                question = input("Wprowadź pytanie: ").capitalize()
                options = input("Wprowadź opcje oddzielone przecinkiem: ").split(',')
                options = [option.capitalize() for option in options]
                while True:
                    correct_answer = input("Wprowadź poprawną odpowiedź: ").capitalize()
                    if correct_answer not in options:
                        print("Poprawna odpowiedź musi być jedną z wprowadzonych opcji.")
                        continue
                    break
                quiz.add_question(question, options, correct_answer, difficulty)
                if input("Czy chcesz dodać kolejne pytanie? (t/n): ").lower() != 't':
                    break
            quiz.save_to_file(args['file'])
    elif args["run"] and args['file']:
        if quiz.load_from_file(args['file']):
            quiz.run_quiz()
    elif args["edit"] and args['file']:
        if quiz.load_from_file(args['file']):
            while True:
                choice = input("""Dostępne opcję:
            d - dodaj pytanie
            u - usuń pytanie
            z - zapisz i wyjdź
Wybierz opcję: """)
                if choice.lower() == 'd':
                    while True:
                        difficulty = input("Wprowadź poziom trudności pytania (łatwe, średnie, trudne): ").capitalize()
                        if difficulty not in ["Łatwe", "Średnie", "Trudne"]:
                            print("Niepoprawny poziom trudności. Wpisz ponownie.")
                            continue
                        break
                    question = input("Wprowadź pytanie: ").capitalize()
                    options = input("Wprowadź opcje oddzielone przecinkiem: ").split(',')
                    options = [option.capitalize() for option in options]
                    
                    while True:
                        correct_answer = input("Wprowadź poprawną odpowiedź: ").capitalize()
                        if correct_answer not in options:
                            print(options)
                            print("Poprawna odpowiedź musi być jedną z wprowadzonych opcji.")
                            continue
                        break
                    quiz.add_question(question, options, correct_answer, difficulty)
                elif choice.lower() == 'u':
                    if not quiz.questions:
                        print("Aktualnie nie ma żadnych pytań w pliku.")
                    else:
                        print("Lista pytań:")
                        for index, question in enumerate(quiz.questions):
                            print(f"{index}. {question['question']}")
                        identifier = input("Wprowadź indeks pytania do usunięcia: ")
                        try:
                            identifier = int(identifier)
                            quiz.remove_question(identifier)
                        except ValueError:
                            print("Wprowadzono niepoprawny indeks. Operacja usunięcia anulowana.")
                elif choice.lower() == 'z':
                    quiz.save_to_file(args['file'])
                    break
                else:
                    print("Wybrano opcje, która nie istnieje.")
    else:
        print_help()

if __name__ == "__main__":
    main()
