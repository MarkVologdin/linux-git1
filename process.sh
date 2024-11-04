#!/bin/bash

# Проверяем, что имя файла передано
if [ $# -eq 0 ]; then
    echo "Использование: $0 имя_файла"
    exit 1
fi

# Сохраняем имя файла в переменной
filename="$1"

# Создаем временный файл для данных в /tmp
datafile="/tmp/data.dat"

# Используем awk для обработки данных
awk -F, '
{
    # Номера колонок
    rating_column_index = 18;
    country_column_index = 7;
    specific_rating_column_index = 12;
    hotel_type_column_index = 1;

    # Проверяем, что значение в колонке 18 не равно -1
    if ($rating_column_index != "" && $rating_column_index != -1) {
        sum += $rating_column_index;
        count++;
    }

    # Приведение названия страны к нижнему регистру и подсчет количества отелей
    if ($country_column_index != "") {
        country = tolower($country_column_index);
        hotel_count[country]++;
    }

    # Определение типа отеля
    hotel_type = "";
    if (tolower($hotel_type_column_index) ~ /holiday_inn/) {
        hotel_type = "holiday_inn";
    } else if (tolower($hotel_type_column_index) ~ /hilton/) {
        hotel_type = "hilton";
    }

    # Подсчет среднего для каждого типа отеля и страны, исключая -1
    if (hotel_type != "" && $specific_rating_column_index != "" && $specific_rating_column_index != -1 && $rating_column_index != "" && $rating_column_index != -1) {
        key = country "|" hotel_type;
        specific_sum[key] += $specific_rating_column_index;
        specific_count[key]++;
    }

    # Записываем данные для линейной регрессии
    if ($rating_column_index != "" && $rating_column_index != -1 &&
        $specific_rating_column_index != "" && $specific_rating_column_index != -1) {
        print $rating_column_index, $specific_rating_column_index >> "'$datafile'";
    }
}

END {
    # Вычисляем и выводим среднее значение с точностью до 5 знаков после запятой
    if (count > 0) {
        printf "RATING_AVG %.5f\n", sum / count;
    } else {
        print "Ошибка: Нет данных для вычисления среднего значения";
    }

    # Выводим количество отелей в каждой стране
    for (country in hotel_count) {
        printf "HOTELNUMBER %s %d\n", country, hotel_count[country];
    }

    # Выводим среднее значение для каждого типа отеля и страны
    for (country in hotel_count) {
        holiday_inn_key = country "|holiday_inn";
        hilton_key = country "|hilton";

        avg_holiday_inn = (specific_count[holiday_inn_key] > 0) ? (specific_sum[holiday_inn_key] / specific_count[holiday_inn_key]) : 0;
        avg_hilton = (specific_count[hilton_key] > 0) ? (specific_sum[hilton_key] / specific_count[hilton_key]) : 0;

        printf "CLEANLINESS %s %.5f %.5f\n", country, avg_holiday_inn, avg_hilton;
    }
}
' "$filename"

# Пишем скрипт gnuplot для построения графика и вычисления линейной регрессии
gnuplot <<- EOF
    set terminal png size 800,600
    set output 'regression.png'
    set title 'Linear Regression of Cleanliness (Column 12) vs. Overall Rating (Column 18)'
    set xlabel 'Overall Rating (Column 18)'
    set ylabel 'Cleanliness (Column 12)'
    set grid

    # Выполнение линейной регрессии
    f(x) = a * x + b
    fit f(x) '$datafile' using 1:2 via a, b

    # Построение графика
    plot '$datafile' using 1:2 title 'Data Points' with points pt 7, \
         f(x) title sprintf('Fit: y = %.2fx + %.2f', a, b) with lines lw 2
EOF

# Удаляем временный файл данных
rm -f "$datafile"
