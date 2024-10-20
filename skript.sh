#!/bin/bash

# Проверка, что передано 2 аргумента
if [ $# -lt 2 ]; then
    echo "Использование: $0 <папка_логов> <порог_процентов>"
    exit 1
fi

LOG_DIR=$1
THRESHOLD=$2
BACKUP_DIR="/backup"
SIZE_LIMIT_MB=1024
N_FILES=10
IMAGE_FILE="./log_image.img"

# Проверка, что папка логов существует
if [ ! -d "$LOG_DIR" ]; then
    echo "Ошибка: папка логов $LOG_DIR не существует!"
    exit 1
fi

# Проверка, что порог в процентах, и это число
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Ошибка: порог должен быть числом от 0 до 100!"
    exit 1
fi

# Проверка, что порог находится в пределах от 1 до 100
if [ "$THRESHOLD" -le 0 ] || [ "$THRESHOLD" -gt 100 ]; then
    echo "Ошибка: порог должен быть в диапазоне от 1 до 100!"
    exit 1
fi

# Проверка и создание файла-образа для ограничения размера папки
if [ ! -f "$IMAGE_FILE" ]; then
    echo "Создаём файл-образ размером $SIZE_LIMIT_MB MB"
    dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=$SIZE_LIMIT_MB
    mkfs.ext4 "$IMAGE_FILE"
    sudo mount -o loop "$IMAGE_FILE" "$LOG_DIR"
else
    echo "Файл-образ уже создан, монтируем в $LOG_DIR"
    sudo mount -o loop "$IMAGE_FILE" "$LOG_DIR"
fi

# Проверка заполненности папки
USED_SPACE=$(df --output=pcent "$LOG_DIR" | tail -n 1 | tr -d ' %')
echo "Заполнено $USED_SPACE% дискового пространства в $LOG_DIR"

# Если заполнена больше порога, архивируем
if [ "$USED_SPACE" -gt "$THRESHOLD" ]; then
    echo "Заполненность больше $THRESHOLD%. Архивируем $N_FILES старых файлов."
    mkdir -p "$BACKUP_DIR"

    # Ищем самые старые файлы и извлекаем путь
    FILES_TO_ARCHIVE=$(sudo find "$LOG_DIR" -type f -printf "%T+ %p\n" | sort | head -n "$N_FILES" | cut -d' ' -f2)

    # Архивируем N_FILES старых файлов
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    TAR_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
    tar -czf "$TAR_FILE" $FILES_TO_ARCHIVE

    # Удаляем заархивированные файлы
    echo "Архив $TAR_FILE создан. Удаляем файлы..."
    sudo rm -f $FILES_TO_ARCHIVE

    echo "Готово!"
else
    echo "Место ещё не закончилось, архивировать ничего не нужно."
fi