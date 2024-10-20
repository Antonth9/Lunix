#!/bin/bash

# Проверка числа аргументов
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <путь_к_исходному_скрипту> <путь_к_текстовому_файлу>"
    exit 1
fi

SOURCE_SCRIPT=$1
INPUT_FILE=$2
REPORT_FILE="$(dirname "$0")/test_report.txt"

# Очистка предыдущего отчета
echo "Отчет о тестировании скрипта" > "$REPORT_FILE"

# Функция генерации случайных логов
generate_random_logs() {
    local log_dir=$1
    local num_files=$(( RANDOM % 28 + 33 ))  # Случайное количество файлов от 33 до 60

    mkdir -p "$log_dir"

    for _ in $(seq 1 $num_files); do
        dd if=/dev/urandom of="$log_dir/log_$(date +%s%N).txt" bs=1M count=16 &>/dev/null
    done
}

# Проверка существования файла и количество строк с тестами
if [ ! -f "$INPUT_FILE" ]; then
    echo "Текстовый файл не найден: $INPUT_FILE"
    exit 1
fi

TEST_COUNT=0

# Чтение каждой строки из текстового файла и выполнение теста
while IFS= read -r line || [ -n "$line" ]; do
    TEST_COUNT=$((TEST_COUNT+1))

    # Разделение строки на два параметра
    LOG_DIR=$(echo "$line" | awk '{print $1}')
    THRESHOLD=$(echo "$line" | awk '{print $2}')

    # Проверка существования директории логов
    if [ ! -d "$LOG_DIR" ]; then
        echo "Директория логов $LOG_DIR не существует. Пропуск теста #$TEST_COUNT" | tee -a "$REPORT_FILE"
        continue
    fi

    # Очистка папки логов
    rm -rf "$LOG_DIR"/*
    mkdir -p "$LOG_DIR"

    # Генерация логов
    generate_random_logs "$LOG_DIR"

    # Выполнить исходный скрипт с параметрами из строки
    OUTPUT=$(bash "$SOURCE_SCRIPT" "$LOG_DIR" "$THRESHOLD" 2>&1)

    # Запись результата теста в файл отчета
    echo -e "Тест #$TEST_COUNT:\n - Директория логов: $LOG_DIR\n - Порог: ${THRESHOLD}%\nРезультат:\n$OUTPUT" >> "$REPORT_FILE"
    echo -e "\n---\n" >> "$REPORT_FILE"  # Разделитель между тестами
done < "$INPUT_FILE"

echo "Тестирование завершено. Всего тестов: $TEST_COUNT."