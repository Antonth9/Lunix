#!/bin/bash

# Проверка аргументов
if [ "$#" -ne 3 ]; then
    echo "Использование: $0 <директория_исходного_скрипта> <расположение_папки_логов> <количество_тестов>"
    exit 1
fi

SCRIPT_DIR=$1
LOGS_DIR=$2
TEST_COUNT=$3
REPORT_FILE="$(dirname "$0")/test_report.txt"

# Очистка предыдущего отчета
echo "Отчет о тестировании скрипта" > $REPORT_FILE

# Функция генерации случайных логов
generate_random_logs() {
    local log_dir=$1
    local num_files=$(( RANDOM % 28 + 33 ))  # Случайное количество файлов от 33 до 60

    mkdir -p "$log_dir"

    for _ in $(seq 1 $num_files); do
        dd if=/dev/urandom of="$log_dir/log_$(date +%s%N).txt" bs=1M count=16 &>/dev/null
    done
}

# Запуск тестов
for (( i=1; i<=$TEST_COUNT; i++ ))
do
    # Очистка папки логов
    rm -rf "$LOGS_DIR"/*
    mkdir -p "$LOGS_DIR"

    # Порог (10-90%)
    THRESHOLD=$(( RANDOM % 21 + 70 ))

    # Генерация логов
    generate_random_logs "$LOGS_DIR"
    
    # Запуск исходного скрипта и сохранение вывода
    OUTPUT=$(bash "$SCRIPT_DIR/skript.sh" "$LOGS_DIR" "$THRESHOLD" 2>&1)
    
    # Запись вывода в отчет
    echo -e "Тест #$i:\n - Количество файлов: $num_files\n - Порог: ${THRESHOLD}%\nРезультат скрипта:\n$OUTPUT" >> $REPORT_FILE
    echo -e "\n---\n" >> $REPORT_FILE  # Разделитель между тестами

    # Вывод в консоль о завершении теста
    echo "Тест #$i завершен."
done

echo "Тестирование завершено. Проверьте файл $REPORT_FILE для получения подробной информации."
