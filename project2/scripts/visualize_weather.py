import os
import json
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime

def load_weather_data():
    """Загрузка всех доступных JSON-файлов с погодными данными"""
    data_dir = 'data'
    all_data = []
    
    for filename in sorted(os.listdir(data_dir)):
        if filename.startswith('weather_') and filename.endswith('.json'):
            filepath = os.path.join(data_dir, filename)
            with open(filepath, 'r') as f:
                all_data.extend(json.load(f))
    
    return pd.DataFrame(all_data)

def create_visualizations(df):
    """Создание визуализаций погодных данных"""
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    reports_dir = 'reports'
    os.makedirs(reports_dir, exist_ok=True)

    # 1. Температура по городам
    plt.figure(figsize=(12, 6))
    for city in df['city'].unique():
        city_data = df[df['city'] == city]
        plt.plot(city_data['timestamp'], city_data['temperature'], label=city)
    
    plt.title('Температура в городах')
    plt.xlabel('Дата')
    plt.ylabel('Температура (°C)')
    plt.legend()
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f'{reports_dir}/temperature_trend.png')
    plt.close()

    # 2. Влажность по городам
    plt.figure(figsize=(12, 6))
    for city in df['city'].unique():
        city_data = df[df['city'] == city]
        plt.plot(city_data['timestamp'], city_data['humidity'], label=city)
    
    plt.title('Влажность в городах')
    plt.xlabel('Дата')
    plt.ylabel('Влажность (%)')
    plt.legend()
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f'{reports_dir}/humidity_trend.png')
    plt.close()

def main():
    df = load_weather_data()
    create_visualizations(df)

if __name__ == "__main__":
    main()
