#!/bin/bash

# Запускаем контейнер PostgreSQL. Можно без указания пути -v echo $path:echo $path
docker run --name sde-pg2 -p 5432:5432  -e POSTGRES_USER=test_sde -e POSTGRES_PASSWORD=@sde_password012 -e POSTGRES_DB=demo -e PGDATA=/var/lib/postgresql/data/pgdata -d -v C:/Users/AGNikolaev/Desktop/sde_test_db/sql:/var/lib/postgresql/data -v C:/Users/AGNikolaev/Desktop/sde_test_db/sql/init_db:/docker-entrypoint-initdb.d postgres

# Даем время на внесение изменений
sleep 60

#  Запускаем скрипт для заполнения БД
docker exec sde-pg2 psql -U test_sde -d demo -f /var/lib/postgresql/data/init_db/demo.sql

sleep 10

# Выводим сообщение об успешном завершении скрипта
echo "Инициализация БД прошла успешна."

sleep 6
