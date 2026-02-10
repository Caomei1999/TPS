import requests
import time
import statistics

BASE_URL = "https://tps-production-c025.up.railway.app"

ENDPOINTS = [
    "/api/parkings/",
    "/api/spots/",
    "/api/cities/",
    "/api/vehicles/",
    "/api/sessions/"
]

HEADERS = {
    "Authorization": "Bearer YOUR_REAL_JWT_TOKEN"
}

def measure(endpoint, iterations=50):
    times = []
    for _ in range(iterations):
        start = time.time()
        r = requests.get(BASE_URL + endpoint, headers=HEADERS)
        elapsed = time.time() - start
        times.append(elapsed)
    return {
        "endpoint": endpoint,
        "avg": statistics.mean(times),
        "p95": statistics.quantiles(times, n=20)[18],
        "max": max(times)
    }

def main():
    results = []
    for ep in ENDPOINTS:
        res = measure(ep)
        results.append(res)
        print(res)

if __name__ == "__main__":
    main()
