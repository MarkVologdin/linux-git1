import os
import json
import requests
from datetime import datetime

class WeatherDataCollector:
    def __init__(self, api_key):
        self.api_key = api_key
        self.cities = [
            {"name": "Moscow", "id": 524901},
            {"name": "Saint Petersburg", "id": 498817},
            {"name": "Novosibirsk", "id": 1496747}
        ]
        self.data_dir = 'data'
        os.makedirs(self.data_dir, exist_ok=True)

    def fetch_city_weather(self, city):
        """Получение погодных данных для конкретного города"""
        url = f"http://api.openweathermap.org/data/2.5/weather"
        params = {
            "id": city['id'],
            "appid": self.api_key,
            "units": "metric"
        }
        
        try:
            response = requests.get(url, params=params)
            response.raise_for_status()
            weather_data = response.json()
            
            processed_data = {
                "city": city['name'],
                "timestamp": datetime.utcnow().isoformat(),
                "temperature": weather_data['main']['temp'],
                "feels_like": weather_data['main']['feels_like'],
                "humidity": weather_data['main']['humidity'],
                "pressure": weather_data['main']['pressure'],
                "wind_speed": weather_data['wind']['speed'],
                "wind_direction": weather_data['wind']['deg']
            }
            
            return processed_data
        
        except requests.exceptions.RequestException as e:
            print(f"Ошибка при получении данных для {city['name']}: {e}")
            return None

    def collect_data(self):
        """Сбор погодных данных для всех городов"""
        all_weather_data = []
        
        for city in self.cities:
            city_data = self.fetch_city_weather(city)
            if city_data:
                all_weather_data.append(city_data)
        
        # Сохранение данных в JSON-файл
        filename = f"{self.data_dir}/weather_{datetime.now().strftime('%Y-%m-%d_%H-%M')}.json"
        with open(filename, 'w') as f:
            json.dump(all_weather_data, f, indent=2)
        
        return filename

def main():
    api_key = os.environ.get('OPENWEATHER_API_KEY')
    if not api_key:
        print("API ключ не установлен!")
        return
    
    collector = WeatherDataCollector(api_key)
    collector.collect_data()

if __name__ == "__main__":
    main()
