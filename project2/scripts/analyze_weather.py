import os
import json
import pandas as pd
from datetime import datetime

def load_weather_data():
    """Загрузка всех доступных JSON-файлов с погодными данными"""
    data_dir = 'data'
    all_data = []

    for filename in sorted(os.listdir(data_dir)):
        if filename.startswith('weather_') and filename.endswith('.json'):
            filepath = os.path.join(data_dir, filename)
            try:
                with open(filepath, 'r') as f:
                    all_data.extend(json.load(f))
            except json.JSONDecodeError as e:
                print(f"Ошибка при чтении {filepath}: {e}")

    if not all_data:
        raise ValueError("Не удалось загрузить данные. Папка 'data' пуста или содержит ошибки.")

    print(f"Успешно считано {len(all_data)} записей из {data_dir}")
    return pd.DataFrame(all_data)

def analyze_weather_trends(df):
    """Анализ трендов погодных данных"""
    if 'timestamp' not in df.columns or 'city' not in df.columns or 'temperature' not in df.columns:
        raise ValueError("Отсутствуют обязательные столбцы в данных (timestamp, city, temperature)")

    df['timestamp'] = pd.to_datetime(df['timestamp'])

    # Группировка по городам и агрегация данных
    city_stats = df.groupby('city').agg({
        'temperature': ['mean', 'min', 'max', 'std'],
        'humidity': ['mean', 'min', 'max'],
        'wind_speed': ['mean', 'max']
    })

    # Создание отчета
    report_dir = 'reports'
    os.makedirs(report_dir, exist_ok=True)
    report_filename = f"weather_analysis_{datetime.now().strftime('%Y-%m-%d')}.md"
    report_path = os.path.join(report_dir, report_filename)

    with open(report_path, 'w') as f:
        f.write("# Анализ погодных данных\n\n")
        f.write(f"**Дата анализа:** {datetime.now().strftime('%Y-%m-%d')}\n\n")

        f.write("## Статистика по городам\n\n")
        f.write(city_stats.to_markdown())

        # Дополнительный анализ температурных аномалий
        f.write("\n## Температурные аномалии\n")
        for city in df['city'].unique():
            city_data = df[df['city'] == city]
            mean_temp = city_data['temperature'].mean()
            std_temp = city_data['temperature'].std()

            anomalies = city_data[
                (city_data['temperature'] > mean_temp + 2*std_temp) | 
                (city_data['temperature'] < mean_temp - 2*std_temp)
            ]

            f.write(f"\n### {city}\n")
            f.write(f"- Средняя температура: {mean_temp:.2f}°C\n")
            f.write(f"- Аномальные значения: {len(anomalies)} обнаружено\n")

    # Вывод информации о пути к отчету
    abs_report_path = os.path.abspath(report_path)
    print(f"Отчет успешно сохранен.\nАбсолютный путь: {abs_report_path}\nОтносительный путь: {report_path}")

def main():
    try:
        df = load_weather_data()
        analyze_weather_trends(df)
    except Exception as e:
        print(f"Ошибка: {e}")

if __name__ == "__main__":
    main()
