import requests
import time
import statistics
from concurrent.futures import ThreadPoolExecutor

BASE_URL = "https://tps-production-c025.up.railway.app"
ENDPOINT = "/api/parkings/"
HEADERS = {"Authorization": "Bearer YOUR_JWT"}

def call():
    start = time.time()
    requests.get(BASE_URL + ENDPOINT, headers=HEADERS)
    return time.time() - start

def main():
    times = []
    with ThreadPoolExecutor(max_workers=10) as ex:
        for t in ex.map(lambda _: call(), range(100)):
            times.append(t)
    print("avg:", statistics.mean(times))
    print("p95:", statistics.quantiles(times, n=20)[18])
    print("max:", max(times))

if __name__ == "__main__":
    main()
