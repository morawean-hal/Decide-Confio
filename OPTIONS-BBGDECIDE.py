import requests
import time
from datetime import datetime
import csv

OPENFIGI_API_KEY = '657692a0-5499-4ded-a8cd-447e3f053ea7'  # <- Trage deinen API-Key ein!

def fetch_figi(bbg_ticker):
    url = "https://api.openfigi.com/v3/mapping"
    headers = {
        'Content-Type': 'application/json',
        'X-OPENFIGI-APIKEY': OPENFIGI_API_KEY
    }
    mapping_job = [{'idType': 'TICKER', 'idValue': bbg_ticker}]
    try:
        resp = requests.post(url, json=mapping_job, headers=headers, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        if not data or not data[0]['data']:
            return ''  # Kein Treffer
        return data[0]['data'][0].get('figi', '')
    except Exception as e:
        return f"Fehler: {e}"

def bbg_to_decide(bbg_line):
    parts = bbg_line.strip().split()
    exchange = 'n/a'
    if len(parts) == 5 and parts[4] == 'Equity':
        underlying = parts[0]
        exch = parts[1]
        if len(exch) in [2, 3]:
            exchange = exch
            country = exch
        else:
            country = 'n/a'
        expiry_str = parts[2]
        callput_strike = parts[3]
    elif len(parts) == 4 and parts[3] == 'Equity':
        underlying = parts[0]
        exchange = 'n/a'
        country = 'n/a'
        expiry_str = parts[1]
        callput_strike = parts[2]
    else:
        raise ValueError("Unerwartetes BBG-Format")

    try:
        expiry_date = datetime.strptime(expiry_str, "%m/%d/%y")
    except:
        try:
            expiry_date = datetime.strptime(expiry_str, "%m/%d/%Y")
        except:
            raise ValueError(f"Ungültiges Datumsformat: {expiry_str}")

    month = expiry_date.strftime("%b").upper()
    day = expiry_date.strftime("%d")
    year = expiry_date.strftime("%y")
    decide_expiry = f"{month}-{day}-{year}"

    callput = callput_strike[0]
    strike = callput_strike[1:]

    decide_country = country if country != 'n/a' else 'n/a'
    decide_code = f"{decide_country}-{underlying} {decide_expiry} {callput} {strike}"
    return decide_code, exchange

input_file = "bbg_ticker.txt"
output_csv = "bbg_to_decide_mapping_figi.csv"

with open(input_file, "r") as fin, open(output_csv, "w", newline='') as fout:
    writer = csv.writer(fout)
    writer.writerow(['Original_BBG', 'Decide_Ticker', 'Exchange_Code_BBG', 'FIGI', 'Status'])
    for line in fin:
        line = line.strip()
        if not line or "Equity" not in line:
            continue
        status = "OK"
        decide_ticker = ""
        exchange = "n/a"
        figi = ""
        try:
            decide_ticker, exchange = bbg_to_decide(line)
            # OpenFIGI-Abfrage (mit Rate-Limiting von max. 20 Requests/Sek)
            figi = fetch_figi(line)
            time.sleep(0.1)  # Safety Pause um OpenFIGI-Nutzung zu schonen
        except Exception as e:
            status = f"Fehler: {e}"
        writer.writerow([line, decide_ticker, exchange, figi, status])
        print(f"{line}  -->  {decide_ticker}  [{exchange}]  [{figi}]  [{status}]")
