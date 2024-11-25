#!/bin/bash

# Проверка наличия аргумента (username)
if [ $# -eq 0 ]; then
    echo "Usage: $0 <github_username>"
    exit 1
fi

# Имя пользователя из аргумента
USERNAME=$1

# Репозиторий для анализа
REPO="datamove/linux-git2"

# Временная директория для кэширования
CACHE_DIR="/tmp/github_pulls_cache"
mkdir -p "$CACHE_DIR"

# Файл для кэширования ответов API
CACHE_FILE="$CACHE_DIR/${USERNAME}_pulls.json"

# Функция для загрузки pull requests
fetch_pulls() {
    local page=$1
    local output_file=$2
    
    # Максимальное количество pull requests на страницу
    curl -s "https://api.github.com/repos/$REPO/pulls?state=all&creator=$USERNAME&per_page=100&page=$page" > "$output_file"
}

# Если кэш пустой или устарел более чем день назад, загружаем заново
if [[ ! -f "$CACHE_FILE" ]] || [[ $(find "$CACHE_FILE" -mtime +1) ]]; then
    # Очищаем предыдущий кэш
    rm -f "$CACHE_FILE"* 2>/dev/null
    
    # Первая страница
    fetch_pulls 1 "${CACHE_FILE}_page1"
    
    # Определяем общее количество страниц
    total_pages=$(curl -si "https://api.github.com/repos/$REPO/pulls?state=all&creator=$USERNAME&per_page=100" | grep -oP 'Link:.*page=\K\d+' | sort -nr | head -1)
    
    # Загружаем остальные страницы, если есть
    if [[ -n "$total_pages" && "$total_pages" -gt 1 ]]; then
        for ((page=2; page<=total_pages; page++)); do
            fetch_pulls "$page" "${CACHE_FILE}_page${page}"
        done
    fi
    
    # Объединяем результаты
    jq -s 'flatten' "${CACHE_FILE}_page"* > "$CACHE_FILE"
    rm "${CACHE_FILE}_page"* 2>/dev/null
fi

# Вычисляем общее количество pull requests
TOTAL_PULLS=$(jq length "$CACHE_FILE")
echo "PULLS $TOTAL_PULLS"

# Находим самый ранний pull request
EARLIEST_PR=$(jq -r 'min_by(.created_at) | .number' "$CACHE_FILE")
echo "EARLIEST $EARLIEST_PR"

# Проверяем, был ли самый ранний pull request смержен
EARLIEST_PR_MERGED=$(jq -r "map(select(.number == $EARLIEST_PR))[0].merged" "$CACHE_FILE")
if [[ "$EARLIEST_PR_MERGED" == "true" ]]; then
    echo "MERGED 1"
else
    echo "MERGED 0"
fi
