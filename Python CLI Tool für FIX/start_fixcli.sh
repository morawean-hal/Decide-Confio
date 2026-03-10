import json
import os
import re
import io
import sys
from collections import defaultdict

ALL_FLOWS = {}
IMPORTED_HASHES = set()

try:
    from rich.console import Console
    from rich.table import Table
    from rich.progress import Progress
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

try:
    from bs4 import BeautifulSoup
    BSOUP_AVAILABLE = True
except ImportError:
    BSOUP_AVAILABLE = False

DB_FILENAME = "_fix_flatfile_db.json"
FIX_MSGTYPE_MAP = {
    "OrdNewReq": "D", "OrdNewAcc": "8", "OrdNewAck": "8", "OrdNewPnd": "8",
    "ExeNewRep": "8", "CancelReq": "F", "CancelReject": "9",
    "OrderCancelReplaceReq": "G", "OrderReplaceReq": "G",
    "TradeCaptureReport": "AE", "AE": "AE", "TradeCaptureReportAck": "AR",
    "QuoteRequest": "R", "Quote": "S",
}


def get_input_with_backspace(prompt=""):
    # Eingabe, bei der Backspace (ASCII 8) sofort als "Back" erkannt wird.
    try:
        import msvcrt
        print(prompt, end="", flush=True)
        chars = b""
        while True:
            c = msvcrt.getch()
            if c == b"\r" or c == b"\n":
                break
            if c == b"\x08":
                print()  # Zeilenumbruch für bessere Optik
                return "\x08"
            if c in (b"\x03", b"\x1b"):  # Strg+C, Esc -> abbruch
                raise KeyboardInterrupt
            # Darstellung, Tipp: Maskiere nicht mit *, sondern gib aus für Zahleneingaben
            print(c.decode("utf-8", errors="ignore"), end="", flush=True)
            chars += c
        print()
        return chars.decode("utf-8", errors="ignore").strip()
    except ImportError:
        # Fallback für Linux/Mac (termios nicht implementiert)
        return input(prompt)


def flatfile_save():
    with open(DB_FILENAME, "w", encoding="utf-8") as f:
        json.dump(ALL_FLOWS, f, ensure_ascii=False, indent=2)

def flatfile_load():
    global ALL_FLOWS
    if os.path.isfile(DB_FILENAME):
        with open(DB_FILENAME, "r", encoding="utf-8") as f:
            ALL_FLOWS = json.load(f)
        print(f"[DB] {len(ALL_FLOWS)} Orders geladen aus {DB_FILENAME}")
    else:
        ALL_FLOWS = {}
        print("[DB] Keine bestehende DB gefunden, starte leer.")

def flatfile_add(newflows):
    update_global_flows(newflows)
    flatfile_save()

def parse_fix_message(line, file_field=''):
    fields = re.split(r'\||\x01', line.strip())
    tags = {}
    for field in fields:
        if "=" in field:
            tag, value = field.split("=", 1)
            tags[tag.strip()] = value.strip()
    if file_field:
        tags["file"] = file_field
    return tags

def parse_partygroups(msg):
    partyids = []
    n = int(msg.get("453", "0")) if "453" in msg and str(msg.get("453")).isdigit() else 0
    if not n:
        return partyids
    parties = []
    keys = list(msg.keys())
    block = []
    for k in keys:
        if k.startswith("448"):
            if block:
                parties.append(block)
                block = []
        if k.startswith(("448", "447", "452")):
            block.append((k, msg[k]))
    if block:
        parties.append(block)
    for group in parties:
        d = {}
        for (k, v) in group:
            d[k[-3:]] = v
        partyids.append(d)
    return partyids

def group_diff(base_g, comp_g):
    diffs = []
    maxlen = max(len(base_g), len(comp_g))
    for i in range(maxlen):
        if i >= len(base_g):
            diffs.append(f"+453.[{i+1}] {comp_g[i]}")
        elif i >= len(comp_g):
            diffs.append(f"-453.[{i+1}] {base_g[i]}")
        else:
            for k in comp_g[i]:
                if comp_g[i][k] != base_g[i].get(k, ""):
                    diffs.append(f"~453.[{i+1}]{k}:{base_g[i].get(k,'')}->{comp_g[i][k]}")
    return diffs

def get_flow_id(fix_dict):
    return fix_dict.get('37') or fix_dict.get('OrderID') or fix_dict.get('11') or fix_dict.get('ClOrdID') or fix_dict.get('17') or fix_dict.get('ExecID') or "unknown"

def msg_uniquekey(msg):
    core = (
        msg.get("file", ""),
        msg.get("37", "") or msg.get("OrderID", ""),
        msg.get("11", "") or msg.get("ClOrdID", ""),
        msg.get("49", ""),
        msg.get("56", ""),
        msg.get("35", ""),
        tuple(sorted(msg.items()))
    )
    return core

def process_fix_paste(content, show_progress=False):
    messages = []
    lines = [l for l in content.strip().splitlines() if "8=FIX" in l]
    total = len(lines)
    dupes = 0
    if RICH_AVAILABLE and show_progress and total > 0:
        with Progress() as progress:
            task = progress.add_task("[cyan]Importiere FIX...", total=total)
            for line in lines:
                msg = parse_fix_message(line)
                key = msg_uniquekey(msg)
                if key in IMPORTED_HASHES:
                    dupes += 1
                elif msg:
                    flow_id = get_flow_id(msg)
                    messages.append((flow_id, msg))
                    IMPORTED_HASHES.add(key)
                progress.update(task, advance=1)
    else:
        for line in lines:
            msg = parse_fix_message(line)
            key = msg_uniquekey(msg)
            if key in IMPORTED_HASHES:
                dupes += 1
            elif msg:
                flow_id = get_flow_id(msg)
                messages.append((flow_id, msg))
                IMPORTED_HASHES.add(key)
    grouped = defaultdict(list)
    for flow_id, msg in messages:
        grouped[flow_id].append(msg)
    return grouped, dupes

def process_csv_paste(content, show_progress=False):
    import csv
    delimiter = '\t' if content.splitlines()[0].count('\t') else ','
    reader = list(csv.DictReader(io.StringIO(content), delimiter=delimiter))
    extracted = []
    total = len(reader)
    dupes = 0
    if RICH_AVAILABLE and show_progress and total > 0:
        with Progress() as progress:
            task = progress.add_task("[magenta]Importiere CSV...", total=total)
            for row in reader:
                file_field = row.get('File', '') or row.get('file', '')
                msg = {k: v for k, v in row.items() if v}
                field_map = {
                    "BeginString": "8", "BodyLength": "9", "MsgSeqNum": "34", "MsgType": "35",
                    "OrderID": "37", "ClOrdID": "11", "ExecID": "17", "SenderCompID": "49",
                    "SenderSubID": "50", "TargetCompID": "56", "TargetSubID": "57",
                    "SendingTime": "52", "TransactTime": "60", "Side": "54", "OrderQty": "38",
                    "Price": "44", "OrdType": "40", "Symbol": "55",
                }
                for logical, tag in field_map.items():
                    if row.get(logical): msg[tag] = row[logical]
                msg["file"] = file_field
                for k, v in [('OrderID', '37'), ('ClOrdID', '11'), ('ExecID', '17'),
                            ('SenderCompID', '49'), ('TargetCompID', '56'),
                            ('OnBehalfOfCompID', '115'), ('OnBehalfOfSubID', '116'),
                            ('DeliverToCompID', '128'), ('DeliverToSubID', '129'),
                            ('MsgType','35')]:
                    if row.get(k): msg[v] = row[k]
                key = msg_uniquekey(msg)
                if key in IMPORTED_HASHES:
                    dupes += 1
                else:
                    extracted.append(msg)
                    IMPORTED_HASHES.add(key)
                progress.update(task, advance=1)
    else:
        for row in reader:
            file_field = row.get('File', '') or row.get('file', '')
            msg = {k: v for k, v in row.items() if v}
            field_map = {
                "BeginString": "8", "BodyLength": "9", "MsgSeqNum": "34", "MsgType": "35",
                "OrderID": "37", "ClOrdID": "11", "ExecID": "17", "SenderCompID": "49",
                "SenderSubID": "50", "TargetCompID": "56", "TargetSubID": "57",
                "SendingTime": "52", "TransactTime": "60", "Side": "54", "OrderQty": "38",
                "Price": "44", "OrdType": "40", "Symbol": "55",
            }
            for logical, tag in field_map.items():
                if row.get(logical): msg[tag] = row[logical]
            msg["file"] = file_field
            for k, v in [('OrderID', '37'), ('ClOrdID', '11'), ('ExecID', '17'),
                        ('SenderCompID', '49'), ('TargetCompID', '56'),
                        ('OnBehalfOfCompID', '115'), ('OnBehalfOfSubID', '116'),
                        ('DeliverToCompID', '128'), ('DeliverToSubID', '129'),
                        ('MsgType','35')]:
                if row.get(k): msg[v] = row[k]
            key = msg_uniquekey(msg)
            if key in IMPORTED_HASHES:
                dupes += 1
            else:
                extracted.append(msg)
                IMPORTED_HASHES.add(key)
    grouped = defaultdict(list)
    for msg in extracted:
        key = get_flow_id(msg)
        grouped[key].append(msg)
    return grouped, dupes

def process_html_paste(html_content):
    if not BSOUP_AVAILABLE:
        print("BeautifulSoup (bs4) ist nicht installiert! Kein HTML-Import möglich.")
        return defaultdict(list), 0
    soup = BeautifulSoup(html_content, features="html.parser")
    extracted = []
    msg_num = 0
    for b in soup.find_all("b"):
        tag_text = b.get_text()
        if "message" in tag_text and "Plain" in tag_text:
            msg_num += 1
            direction = "Incoming" if "Incoming" in tag_text else ("Outgoing" if "Outgoing" in tag_text else "")
            t = b.find_next("table")
            if t:
                msg = {}
                for tr in t.find_all("tr"):
                    tds = tr.find_all("td")
                    if len(tds) == 4:
                        tag = tds[1].get_text(strip=True)
                        if tag.isdigit():
                            value = tds[3].get_text(strip=True)
                            if tag and value:
                                msg[tag] = value
                msg["log_msg_num"] = str(msg_num)
                msg["msg_direction"] = direction
                key = msg_uniquekey(msg)
                if key in IMPORTED_HASHES or not msg:
                    continue
                extracted.append(msg)
                IMPORTED_HASHES.add(key)
    grouped = defaultdict(list)
    for msg in extracted:
        key = get_flow_id(msg)
        grouped[key].append(msg)
    return grouped, 0

def extract_comp_ids(fixmsg):
    return {
        "SenderCompID": fixmsg.get("49", "") or fixmsg.get("SenderCompID", ""),
        "TargetCompID": fixmsg.get("56", "") or fixmsg.get("TargetCompID", ""),
        "OnBehalfOfCompID": fixmsg.get("115", ""),
        "OnBehalfOfSubID": fixmsg.get("116", ""),
        "DeliverToCompID": fixmsg.get("128", ""),
        "DeliverToSubID": fixmsg.get("129", ""),
        "file": fixmsg.get("file", "")
    }

def update_global_flows(newflows):
    for k, v in newflows.items():
        if k in ALL_FLOWS:
            ALL_FLOWS[k].extend(v)
        else:
            ALL_FLOWS[k] = v

def compare_tagsets(base, compare):
    added = []
    changed = []
    for k, v in compare.items():
        if k in ("file", ""):
            continue
        if k not in base:
            added.append(f"+{k}={v}")
        elif base[k] != v:
            changed.append(f"~{k}={base[k]}→{v}")
    return added, changed

def get_oms_diffs(messages):
    c_file = [m for m in messages if m.get("file", "").upper().endswith("C")]
    o_file = [m for m in messages if m.get("file", "") and not m.get("file", "").upper().endswith("C")]
    step_strings = []
    if c_file and o_file:
        c = c_file[0]
        o_file_sorted = sorted(o_file, key=lambda x: int(x.get("MsgSeqNum", "0")) if x.get("MsgSeqNum") and x.get("MsgSeqNum").isdigit() else 0)
        for idx, oms in enumerate(o_file_sorted):
            added, changed = compare_tagsets(c, oms)
            parts = added + changed
            if c.get('453') or oms.get('453'):
                base_grp = parse_partygroups(c)
                comp_grp = parse_partygroups(oms)
                groupdiffs = group_diff(base_grp, comp_grp)
                parts += groupdiffs
            step_diff = " | ".join(parts)
            if step_diff:
                step_strings.append(f"Step{idx+1}: {step_diff}")
            c = oms
    return " ; ".join(step_strings) if step_strings else ""

def fancy_fix_output(grouped):
    console = Console()
    for flow_id, msgs in grouped.items():
        oms_changes = get_oms_diffs(msgs)
        console.rule(f"[bold green]Flow: {flow_id} ({len(msgs)} Nachrichten)")
        table = Table(show_header=True, header_style="bold magenta")
        table.add_column("MsgType", style="bold cyan")
        table.add_column("SenderCompID")
        table.add_column("TargetCompID")
        table.add_column("OrderID")
        table.add_column("ClOrdID")
        table.add_column("OMS-Änderungen", style="green", overflow="fold")
        table.add_column("file")
        for msg in msgs:
            cids = extract_comp_ids(msg)
            table.add_row(
                msg.get("35", "") or msg.get("MsgType", ""),
                cids['SenderCompID'],
                cids['TargetCompID'],
                msg.get("37", "") or msg.get("OrderID", ""),
                msg.get("11", "") or msg.get("ClOrdID", ""),
                oms_changes,
                cids.get("file", "")
            )
        console.print(table)

def simple_fix_output(grouped):
    for flow_id, msgs in grouped.items():
        oms_changes = get_oms_diffs(msgs)
        print(f"\nFlow: {flow_id} ({len(msgs)} Nachrichten)")
        for msg in msgs:
            cids = extract_comp_ids(msg)
            print(f"{msg.get('35', ''):>3} Sender:{cids['SenderCompID']} Target:{cids['TargetCompID']} "
                  f"OrderID:{msg.get('37','')} ClOrdID:{msg.get('11','')} File:{cids['file']} OMS:{oms_changes}")

def create_spoof_fix(fixmsg):
    tag_values = []
    for k, v in fixmsg.items():
        if k == "35":
            v = FIX_MSGTYPE_MAP.get(v, v)
        if not k.isdigit():
            continue
        if k == "11":
            tag_values.append(f"{k}=<OrdID+1>")
        elif k == "52":
            tag_values.append(f"{k}=<NowMS>")
        elif k in ("34", "43"):
            tag_values.append(f"{k}=<SEQ>")
        elif k == "10":
            tag_values.append(f"{k}=<CSum>")
        else:
            tag_values.append(f"{k}={v}")
    header_keys = ["8", "9", "35"]
    header_kvs = [kv for kv in tag_values if kv.split("=")[0] in header_keys]
    rest = [kv for kv in tag_values if kv.split("=")[0] not in header_keys]
    sorted_string = header_kvs + rest
    return '\x01'.join(sorted_string) + '\x01'

def search_orders():
    if not ALL_FLOWS:
        print("Noch keine Orders/FIX-Flows geladen!")
        return
    filter_val = input("OrderID/ClOrdID/CompID/File(substring)/leer für alle: ").strip()
    result = []
    for fid, msgs in ALL_FLOWS.items():
        for msg in msgs:
            if (not filter_val
                or filter_val in fid
                or filter_val in msg.get("37", "") or filter_val in msg.get("OrderID", "")
                or filter_val in msg.get("11", "") or filter_val in msg.get("ClOrdID", "")
                or filter_val in msg.get("49", "") or filter_val in msg.get("SenderCompID", "")
                or filter_val in msg.get("56", "") or filter_val in msg.get("TargetCompID", "")
                or filter_val in msg.get("file", "") or filter_val in msg.get("MsgType", "")):
                result.append((fid, msg, msgs))
    if not result:
        print("Keine Treffer.")
        return

    def show_main_table():
        if RICH_AVAILABLE:
            console = Console()
            table = Table(show_header=True, header_style="bold magenta")
            table.add_column("Num", justify="right")
            table.add_column("OrderID")
            table.add_column("ClOrdID")
            table.add_column("SenderCompID")
            table.add_column("TargetCompID")
            table.add_column("MsgType")
            table.add_column("file")
            for idx, (fid, msg, msgs) in enumerate(result, 1):
                table.add_row(
                    str(idx),
                    msg.get("37", "") or msg.get("OrderID", ""),
                    msg.get("11", "") or msg.get("ClOrdID", ""),
                    msg.get("49", "") or msg.get("SenderCompID", ""),
                    msg.get("56", "") or msg.get("TargetCompID", ""),
                    msg.get("35", "") or msg.get("MsgType", ""),
                    msg.get("file", "")
                )
            console.print(table)
        else:
            for idx, (fid, msg, msgs) in enumerate(result, 1):
                print(f"[{idx}] {msg.get('37','')} {msg.get('11','')} {msg.get('49','')} {msg.get('56','')} {msg.get('file','')} {msg.get('35','')}")

    def show_fix_and_diff(msg, msgs):
        print("\n===== FIX-String (copy/paste-ready, mit SOH): =====\n")
        rawstring = create_spoof_fix(msg)
        print(rawstring)
        print("\n===== Zusammenfassung OMS-Änderungen (verglichen mit Ursprungsnachricht): =====")
        print(get_oms_diff_to_orig(msg, msgs) or "(keine Änderungen im Vergleich zum Ursprung/keine Vergleichsnachricht)")
        print("\nZurück mit [Backspace]...")

    def get_oms_diff_to_orig(selected, alle):
        origs = [m for m in alle if m.get("file", "").upper().endswith("C")]
        if not origs:
            return ""
        orig = origs[0]
        a, c = compare_tagsets(orig, selected)
        parts = a + c
        if orig.get('453') or selected.get('453'):
            base_grp = parse_partygroups(orig)
            comp_grp = parse_partygroups(selected)
            groupdiffs = group_diff(base_grp, comp_grp)
            parts += groupdiffs
        return " | ".join(parts)

    while True:
        show_main_table()
        select = get_input_with_backspace("Nr. auswählen für Details ([Backspace]=zurück): ")
        if select == "\x08" or not select or not select.isdigit():
            return
        idx = int(select)
        if idx < 1 or idx > len(result):
            print("Ungültig!")
            continue
        _, sel_msg, sub_msgs = result[idx-1]
        show_fix_and_diff(sel_msg, sub_msgs)
        # Warte auf BACKSPACE zum Zurückgehen
        while True:
            c = get_input_with_backspace("")
            if c == "\x08":
                break

def check_libs():
    missing = []
    if not RICH_AVAILABLE:
        missing.append("rich (kein Fancy-Output/Fortschrittsbalken)")
    if not BSOUP_AVAILABLE:
        missing.append("beautifulsoup4 (kein HTML-Logimport)")
    if missing:
        print("\n[WARNUNG] Für alle Komfortfunktionen fehlen folgende Module:")
        for m in missing:
            print("  -", m)
        print("Bitte ggf. von IT installieren lassen (pip install rich beautifulsoup4)\n")
    else:
        print("✔️ Alle Zusatzmodule installiert!")

def main_menu():
    check_libs()
    while True:
        print("\nWas möchtest du tun?")
        print("1 = FIX RAW Nachrichten einfügen und auswerten")
        print("2 = Excel-/CSV-Tabellenblock einfügen und auswerten")
        print("3 = Bereits eingelesene Orders suchen/ausgeben/kopieren")
        if BSOUP_AVAILABLE:
            print("4 = HTML Log/Export einfügen und auswerten")
        print("0 = Beenden")
        choice = get_input_with_backspace("Auswahl (1/2/3/4/0): ")
        if choice == "\x08" or choice == "0":
            print("Bye!")
            break
        if choice == "3":
            search_orders()
            continue
        if choice == "4" and BSOUP_AVAILABLE:
            print("\nHTML Export reinpasten (mit Tabellen), dann einmal ENTER oder [Backspace] für zurück:")
            html_data = []
            while True:
                line = get_input_with_backspace("")
                if line == "\x08":
                    break
                html_data.append(line)
                if not line.strip():
                    break
            html_block = "\n".join(html_data).strip()
            if not html_block:
                print("Nichts eingegeben.")
                continue
            grouped, _ = process_html_paste(html_block)
            if not grouped:
                print("Keine Nachrichten verstanden!")
                continue
            flatfile_add(grouped)
            if RICH_AVAILABLE:
                fancy_fix_output(grouped)
            else:
                simple_fix_output(grouped)
            continue
        if choice not in ("1", "2", "3", "4"):
            print("Ungültige Auswahl.")
            continue
        print("\nBitte jetzt die Daten (Paste, dann einmal nur ENTER oder [Backspace] für zurück):")
        try:
            data = []
            while True:
                line = get_input_with_backspace("")
                if line == "\x08":
                    break
                data.append(line)
                if not line.strip():
                    break
            data = "\n".join(data).strip()
        except EOFError:
            data = ""
        if not data:
            print("Keine Daten eingegeben.")
            continue
        show_progress = RICH_AVAILABLE
        grouped = None
        dupes = 0
        if choice == "1":
            grouped, dupes = process_fix_paste(data, show_progress=show_progress)
            if not grouped:
                out = "[red]Keine gültigen FIX-Nachrichten erkannt!" if RICH_AVAILABLE else "Keine gültigen FIX-Nachrichten erkannt!"
                print(out)
                continue
        elif choice == "2":
            grouped, dupes = process_csv_paste(data, show_progress=show_progress)
            if not grouped:
                out = "[red]Kein gültiger CSV-Import – keine Zeilen gefunden!" if RICH_AVAILABLE else "Kein gültiger CSV-Import – keine Zeilen gefunden!"
                print(out)
                continue
        else:
            continue
        flatfile_add(grouped)
        n = sum(len(v) for v in grouped.values())
        summary = f"\n>>> {n} Nachrichten importiert."
        if dupes:
            summary += f" {dupes} Duplikate erkannt (nicht gespeichert)!"
        print(summary)
        if RICH_AVAILABLE:
            fancy_fix_output(grouped)
        else:
            simple_fix_output(grouped)

if __name__ == "__main__":
    flatfile_load()
    main_menu()
