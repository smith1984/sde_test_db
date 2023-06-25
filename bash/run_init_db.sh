#!/bin/bash
# Определяем переменные окружения
POSTGRES_CONTAINER_NAME="ps-sdb"              # Имя контейнера PostgreSQL
POSTGRES_USER="test_sde"                      # Имя пользователя базы данных
POSTGRES_PASSWORD="@sde_password012"          # Пароль пользователя базы данных
POSTGRES_DB="demo"                            # Имя базы данных
POSTGRES_PORT=5432                            # Порт PostgreSQL
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw" ]]; then
  echo "Git Bash запущена в среде Windows."
  PROJECT_SQL_DIR="/$(pwd)/../sql"              # Путь к директории проекта SQL
else
  echo "Git Bash запущена в среде Linux или другой UNIX-подобной системе."
  PROJECT_SQL_DIR="$(pwd)/../sql"              # Путь к директории проекта SQL
fi

CONTAINER_SQL_DIR="/sql"
INIT_SCRIPT="$(pwd)/../sql/init_db/demo.sql"                # Имя SQL-файла для инициализации базы данных

# Вывод пути до SQL-файла для инициализации базы данных
echo "Путь до SQL-файла для инициализации базы данных"
echo "$INIT_SCRIPT"
echo "$CONTAINER_SQL_DIR"

# Cкачиваем docker образ postgres
echo "Cкачиваем docker образ postgres"
docker pull postgres:latest

# Создаем и запускаем контейнер PostgreSQL
echo "Создаем и запускаем контейнер PostgreSQL"

docker run --name "$POSTGRES_CONTAINER_NAME" \
-e POSTGRES_USER="$POSTGRES_USER" \
-e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
-e POSTGRES_DB="$POSTGRES_DB" \
-p "$POSTGRES_PORT":5432 \
-v "$PROJECT_SQL_DIR":"$CONTAINER_SQL_DIR" \
-d postgres

# Ожидаем, пока контейнер PostgreSQL запустится
echo "Ожидание запуска контейнера PostgreSQL 5 секунд"
sleep 5
#
# Импортируем SQL-файл с инициализацией базы данных
docker exec -i "$POSTGRES_CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$INIT_SCRIPT"

# Выводим сообщение об успешной инициализации
echo "База данных успешно инициализирована."
