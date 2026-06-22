import asyncio
import aiohttp
import time
import json
import os
import statistics

# Configuration
CONCURRENT_USERS = 40
TEST_DURATION_SECS = 5
TARGET_API = os.getenv('TARGET_API_URL', 'http://localhost:8080')
ENDPOINTS = [
    '/api/listings',
    '/api/spaces',
    '/api/chat/rooms'
]

async def send_request(session, url, results):
    start_time = time.time()
    try:
        async with session.get(url) as response:
            status = response.status
            await response.read()
            latency = (time.time() - start_time) * 1000 # convert to ms
            results.append({
                'url': url,
                'status': status,
                'latency_ms': latency,
                'success': status in [200, 201]
            })
    except Exception as e:
        latency = (time.time() - start_time) * 1000
        results.append({
            'url': url,
            'status': 500,
            'latency_ms': latency,
            'success': False,
            'error': str(e)
        })

async def run_worker(session, url, queue, results, stop_event):
    while not stop_event.is_set():
        await send_request(session, url, results)
        await asyncio.sleep(0.1) # small throttle between user loops

async def main():
    print(f"Starting LocalSync Load Test benchmark against {TARGET_API}...")
    print(f"Parameters: {CONCURRENT_USERS} concurrent users across {len(ENDPOINTS)} endpoints.")
    
    results = []
    stop_event = asyncio.Event()
    
    async with aiohttp.ClientSession() as session:
        tasks = []
        for i in range(CONCURRENT_USERS):
            endpoint = ENDPOINTS[i % len(ENDPOINTS)]
            url = f"{TARGET_API.rstrip('/')}{endpoint}"
            tasks.append(asyncio.create_task(run_worker(session, url, None, results, stop_event)))
        
        # Run load test for specified duration
        await asyncio.sleep(TEST_DURATION_SECS)
        stop_event.set()
        
        # Gather all run threads
        await asyncio.gather(*tasks, return_exceptions=True)
        
    # Analyze and compile stats
    total_reqs = len(results)
    if total_reqs == 0:
        print("Error: No load test requests were completed.")
        return
        
    latencies = [r['latency_ms'] for r in results]
    successes = [r for r in results if r['success']]
    failures = [r for r in results if not r['success']]
    rate_limits = [r for r in results if r['status'] == 429]
    
    avg_latency = statistics.mean(latencies) if latencies else 0
    min_latency = min(latencies) if latencies else 0
    max_latency = max(latencies) if latencies else 0
    
    # Calculate 95th percentile
    latencies.sort()
    idx_95 = int(len(latencies) * 0.95)
    p95_latency = latencies[idx_95] if latencies else 0
    
    rps = total_reqs / TEST_DURATION_SECS
    success_rate = (len(successes) / total_reqs) * 100
    
    summary = {
        'target_api': TARGET_API,
        'concurrent_users': CONCURRENT_USERS,
        'duration_seconds': TEST_DURATION_SECS,
        'total_requests': total_reqs,
        'requests_per_second': rps,
        'average_latency_ms': avg_latency,
        'min_latency_ms': min_latency,
        'max_latency_ms': max_latency,
        'p95_latency_ms': p95_latency,
        'success_rate_percent': success_rate,
        'failed_requests_count': len(failures),
        'rate_limited_count': len(rate_limits),
        'status_codes': {}
    }
    
    # Count status code frequencies
    for r in results:
        code = str(r['status'])
        summary['status_codes'][code] = summary['status_codes'].get(code, 0) + 1
        
    # Output to JSON
    output_path = os.path.join(os.path.dirname(__file__), 'load_results.json')
    with open(output_path, 'w') as f:
        json.dump(summary, f, indent=2)
        
    print(f"Load test finished. Results written to {output_path}")
    print(f"RPS: {rps:.2f} | P95 Latency: {p95_latency:.2f}ms | Success Rate: {success_rate:.1f}%")

if __name__ == '__main__':
    asyncio.run(main())
