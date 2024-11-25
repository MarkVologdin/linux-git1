#!/bin/bash

# Проверка на наличие аргумента
if [ -z "$1" ]; then
  echo "Использование: $0 <github-username>"
  exit 1
fi

GITHUB_USER="$1"
REPO="datamove/linux-git2"
TOKEN_PATH="/home/users/$USER/public_repo_token"

# Чтение токена из файла
if [ ! -f "$TOKEN_PATH" ]; then
  echo "Токен не найден по пути $TOKEN_PATH"
  exit 1
fi

TOKEN=$(cat "$TOKEN_PATH")

# Инициализация переменной для хранения всех пулл-реквестов
all_pulls=""

# Пагинация для получения всех пулл-реквестов (в случае, если их больше 100)
page=1
while : ; do
  # Получение страницы пулл-реквестов с использованием токена
  response=$(curl -X GET -s -H "Authorization: token $TOKEN" "https://api.github.com/repos/$REPO/pulls?state=all&per_page=100&page=$page")

  # Проверка на пустую страницу
  pulls_on_page=$(echo "$response" | jq '. | length')
  if [ "$pulls_on_page" -eq 0 ]; then
    break
  fi

  # Добавление к общему списку
  all_pulls+=$(echo "$response" | jq '.[]')

  # Увеличение номера страницы
  page=$((page + 1))
done

# Фильтрация пулл-реквестов по имени пользователя
user_pulls=$(echo "$all_pulls" | jq -s '. | map(select(.user.login=="'"$GITHUB_USER"'"))')

# Подсчет всех пулл-реквестов
pulls_count=$(echo "$user_pulls" | jq 'length')
echo "PULLS $pulls_count"

if [ "$pulls_count" -eq 0 ]; then
  echo "EARLIEST 0"
  echo "MERGED 0"
  exit 0
fi

# Получение самого раннего пулл-реквеста
earliest_pr=$(echo "$user_pulls" | jq -r 'sort_by(.created_at) | .[0]')
earliest_pr_number=$(echo "$earliest_pr" | jq -r '.number')
echo "EARLIEST $earliest_pr_number"

# Проверка, был ли самый ранний пулл-реквест смержен
merged=$(echo "$earliest_pr" | jq -r '.merged_at != null')
if [ "$merged" = "true" ]; then
  echo "MERGED 1"
else
  echo "MERGED 0"
fi
