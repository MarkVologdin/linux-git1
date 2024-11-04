#!/bin/bash

# Путь к файлу
DATASET="$1"
TEMP_DIR="/home/users/MarkVologdin/linux-git1/tmp"

# 1. Средний рейтинг (overall_ratingsource)
RATING_AVG=$(awk -F',' '$18 != "-1.0" && $18 != "overall_ratingsource" {sum+=$18; count++} END {if (count > 0) print sum/count; else print "0"}' "$DATASET")
echo "RATING_AVG $RATING_AVG"

# 2. Число отелей в каждой стране
# Предположим, что страна указана в поле country, столбец 7, и преобразуем к нижнему регистру
awk -F',' 'NR > 1 && $7 != "" {country=tolower($7); count[country]++} END {for (c in count) print "HOTELNUMBER", c, count[c]}' "$DATASET"

# 3. Средний балл cleanliness по стране для отелей сети Holiday Inn и Hilton

awk -F',' '
NR > 1 && $12 != "-1.0" && $2 ~ /(holiday inn|hilton)/ {
    hotel = ($2 ~ /holiday inn/) ? "holidayinn" : "hilton"
    country = tolower($7)
    key = country "_" hotel
    
    
    cleanliness[key] += $12
    count[key]++
    
}
END {
   for (k in cleanliness) {
        split(k, arr, "_")
        country = arr[1]
        hotel = arr[2]
        avg = cleanliness[k] / count[k]
        
        if (hotel == "holidayinn") {
            hol_avg[country] = avg
        } else if (hotel == "hilton") {
            hil_avg[country] = avg
        }
    }
    

    # Итоговый вывод
    for (c in hol_avg) {
        print "CLEANLINESS", c, hol_avg[c], (hil_avg[c] ? hil_avg[c] : "N/A")
    }
}' "$DATASET"


# 4. Построение линейной регрессии с использованием Gnuplot
# Создаем временный файл для данных Gnuplot
DATA_FILE="$TEMP_DIR/cleanliness_vs_overall.dat"
awk -F',' '$12 != "-1.0" && $18 != "-1.0" {print $12, $18}' "$DATASET" > "$DATA_FILE"

# Создаем командный файл для Gnuplot
PLOT_FILE="$TEMP_DIR/cleanliness_vs_overall.plot"
cat << EOF > "$PLOT_FILE"
set terminal png size 800,600
set output 'home/users/MarkVologdin/linux-git1/tmp/cleanliness_vs_overall.png'
set xlabel 'Overall Rating'
set ylabel 'Cleanliness'
set title 'Regression: Cleanliness vs Overall Rating'
set grid
f(x) = a*x + b
fit f(x) '$DATA_FILE' using 2:1 via a,b
plot '$DATA_FILE' using 2:1 title 'Data Points' with points, \
     f(x) title 'Fit Line' with lines
EOF

# Запуск Gnuplot
gnuplot "$PLOT_FILE"

# Уведомление о завершении
echo "Результаты сохранены в /tmp/cleanliness_vs_overall.png"

