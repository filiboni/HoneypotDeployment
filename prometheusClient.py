import json
import time
from prometheus_client import start_http_server, Counter, Histogram, Gauge
import subprocess

connections = {}
counters = {}

def try_read_file():
    while True:
        try:
            with open('/ctrl1/log.json', 'r') as f:
                return [json.loads(line) for line in f]
        except (IOError, ValueError):
            print("Errore durante la lettura del file, riprovo tra 2 secondi...")
            time.sleep(2)

def collect_metrics():
    # Esegui il comando Linux per ottenere le metriche
    command = "VBoxManage metrics query HON1 Guest/CPU/Load/User,Guest/CPU/Load/Kernel,Guest/RAM/Usage/Total | awk '{print $3}'"

    output = subprocess.check_output(command, shell=True).decode("utf-8").strip().split("\n")

    cpu_user_load = float(output[2].rstrip('%'))
    cpu_kernel_load = float(output[3].rstrip('%'))
    ram_usage = int(output[4])

    # Imposta i valori delle metriche
    cpu_user_load_metric.set(cpu_user_load)
    cpu_kernel_load_metric.set(cpu_kernel_load)
    ram_usage_metric.observe(ram_usage)

def update_stats():
    print("Updating stats...")
    data = try_read_file()
    for line in data:
        connection = line.get('connection')
        protocol = line.get('connection_protocol')
        type = line.get('connection_type')
        op = line.get('eventid')
        if(type == "accept" and (op == "connection" or op == "login")):
            if protocol in connections:
                connections[protocol].append(connection)
            else:
                connections[protocol] = [connection]

    for protocol, values in connections.items():
        unique_values = set(values)
        print("-----------------------------------------------")
        print("Campo {}: {} connessioni diverse".format(protocol, len(unique_values)))
        if protocol not in counters:
            counters[protocol] = Counter(protocol + '_connections', 'Number of ' + protocol + ' connections')
        counters[protocol]._value.set(len(unique_values))

if __name__ == '__main__':
    # Crea i Gauge per le metriche
    cpu_user_load_metric = Gauge("honeypot_cpu_load_user", "Guest CPU User Load")
    cpu_kernel_load_metric = Gauge("honeypot_cpu_load_kernel", "Guest CPU Kernel Load")
    ram_usage_metric = Histogram("honeypot_ram_usage", "Guest RAM Usage (KB)")

    # Avvia il server Prometheus
    start_http_server(8000)

    print("Prometheus server started on port 8000")

    while True:
        try:
            collect_metrics()
            update_stats()
            time.sleep(30)
        except KeyboardInterrupt:
            print("Stopping server")
            break


