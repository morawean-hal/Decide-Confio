1. Konzept: Was brauchst du als Ausgangspunkt?
Mindestens folgende Infos pro Optionsserie:
Basiswert (Underlying, z. B. ISIN, Name)
Instrumenten-Parameter (z. B. Währung, Börse…)
Strike-Preise (Liste)
Expiry-Daten (Liste oder Datum)
Style (amerikanisch/europäisch…)
Call/Put Unterscheidung
ggf. weitere Felder für DECIDE-Import (exchangeID, size, WKN, etc.)
Für Futures ist es meist: Underlying, Kontraktmonat, Größe, ggf. Verfall, usw.

2. Grundaufbau einer Beispiel-Options-DB mit Python und Pandas
import pandas as pd
from datetime import date

# Beispiel: Optionen auf Sanofi
db = pd.DataFrame([
    # underlying, expiry, strike, callput, style
    {'isin': 'FR0000120578', 'expiry': date(2024, 9, 20), 'strike': 85, 'callput': 'C', 'style': 'E'},
    {'isin': 'FR0000120578', 'expiry': date(2024, 9, 20), 'strike': 85, 'callput': 'P', 'style': 'E'},
    {'isin': 'FR0000120578', 'expiry': date(2024, 9, 20), 'strike': 90, 'callput': 'C', 'style': 'E'},
    {'isin': 'FR0000120578', 'expiry': date(2024, 9, 20), 'strike': 90, 'callput': 'P', 'style': 'E'},
    # usw.
])
Du kannst solche Tabellen auch automatisch generieren:

from itertools import product

underlying = 'FR0000120578'
strikes = [80, 82.5, 85, 87.5, 90]
expiries = [date(2024,9,20), date(2024,12,20)]
option_types = ['C', 'P']
style = 'E'

series = []
for expiry, strike, ctype in product(expiries, strikes, option_types):
    series.append({'isin': underlying, 'expiry': expiry, 'strike': strike, 'callput': ctype, 'style': style})
db = pd.DataFrame(series)
3. Vom DataFrame zur DECIDE-Import-Struktur (XML/CSV)
Für DECIDE brauchst du typischerweise (mindestens):

EIN Instrument-Objekt pro Serie (z. B. alle Optionen auf einen Underlying/Verfall zusammen)
EIN Contract pro Option/Future-Kontrakt (mit Strike, Verfallsdatum, Call/Put, etc.)
Beispiel: Datensatz zu XML für DECIDE

Instrument:
<instrument id="OPT_SANOFI_20240920" type="Option">
  <name>Sanofi Option Series Sep24</name>
  <instrumentId>OPT_SANOFI_20240920</instrumentId>
  <underlying><id>FR0000120578</id></underlying>
  <currency>EUR</currency>
  <strikeCurrency>EUR</strikeCurrency>
  <primaryExchange>XPAR</primaryExchange>
  <expiryTime>18:00</expiryTime>
  <style>E</style>
  <exchangeID>XPAR_OPT</exchangeID>
</instrument>
Contracts:
<contract type="Option">
  <base><id>OPT_SANOFI_20240920</id></base>
  <expiry>2024-09-20</expiry>
  <callput>C</callput>
  <version>1</version>
  <size>100</size>
  <strike>85</strike>
</contract>
usw. für jede Strike/CallPut-Kombination.

4. Python: CSV/DF zu DECIDE-XML
from datetime import date

def instrument_xml(instrument_id, name, isin, currency, strike_currency, exchange, style):
    return f"""<instrument id="{instrument_id}" type="Option">
  <name>{name}</name>
  <instrumentId>{instrument_id}</instrumentId>
  <underlying><id>{isin}</id></underlying>
  <currency>{currency}</currency>
  <strikeCurrency>{strike_currency}</strikeCurrency>
  <primaryExchange>{exchange}</primaryExchange>
  <expiryTime>18:00</expiryTime>
  <style>{style}</style>
  <exchangeID>{exchange}_OPT</exchangeID>
</instrument>
"""

def contract_xml(instrument_id, expiry, callput, strike, version="1", size="100"):
    return f"""<contract type="Option">
  <base><id>{instrument_id}</id></base>
  <expiry>{expiry}</expiry>
  <callput>{callput}</callput>
  <version>{version}</version>
  <size>{size}</size>
  <strike>{strike}</strike>
</contract>
"""

# Erzeuge Instrument+Contracts für die Serie
def option_series_to_xml(df):
    # Gruppiere z. B. nach ISIN und expiry zu einer Serie
    xml = []
    for (isin, expiry), group in df.groupby(['isin','expiry']):
        instr_id = f"OPT_{isin}_{expiry.strftime('%Y%m%d')}"
        xml.append(instrument_xml(instr_id, f"Option Serie {isin} {expiry}", isin, "EUR", "EUR", "XPAR", "E"))
        for _, row in group.iterrows():
            xml.append(contract_xml(instr_id, row.expiry.strftime('%Y-%m-%d'), row.callput, row.strike))
    return "\n".join(xml)

print(option_series_to_xml(db))
5. Ergebnis/Workflow
So pflegst/generierst du serienweise Optionen (bzw. auch Futures) mit Python
Die XML kannst du als Files ausgeben und direkt in DECIDE importieren
Mit ein paar Zeilen kannst du auch andere Exportformate (CSV, JSON, Excel) erzeugen
Für Futures ist der Aufbau nahezu identisch!
Fragen zur Anpassung (z.B. weitere Felder wie WKN, Valoren, Min-Tick)?
Oder willst du eine Mini-Web-Schnittstelle/Pandas-GUI/Lies-dein-Eurex Masterfile als Input?

Sag mir, wie konkret du arbeiten willst, dann bekommst du einen zu deiner Praxis passenden “Baukasten” dazu!
