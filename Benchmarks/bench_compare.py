#!/usr/bin/env python3
"""
Parse Swift Benchmark markdown (produced by `swift package benchmark ... --format markdown`) and produce compact summary
markdown tables for Decoding and Encoding using the Time (total CPU) p50 values.

Usage:
  - Read from stdin:
      swift package benchmark baseline compare swiftcbor --format markdown --no-progress | python3 bench_compare.py
  - Or read from file:
      python3 bench_compare.py benchmark.md

The script prints two markdown tables (Decoding and Encoding) to stdout.
"""

import sys
import re
from pathlib import Path


def parse_markdown(text):
    lines = text.splitlines()
    results = {"Decoding": {}, "Encoding": {}}
    mode = None
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip().startswith('## Decoding'):
            mode = 'Decoding'
            i += 1
            continue
        if line.strip().startswith('## Encoding'):
            mode = 'Encoding'
            i += 1
            continue

        m = re.match(r"###\s+(.+?)\s+metrics", line)
        if m and mode:
            bench = m.group(1).strip()
            # look ahead for Time (total CPU) table
            j = i + 1
            while j < len(lines) and not lines[j].strip().startswith('###') and not lines[j].strip().startswith('## '):
                lh = lines[j]
                # find the section header line containing "Time (total CPU)"
                m2 = re.search(r"Time\s*\(total CPU\)\s*(?:\(([^)]+)\))?", lh)
                if m2:
                    unit = m2.group(1) if m2.group(1) else ''
                    # find the header row that contains p0/p25/p50 etc.
                    k = j + 1
                    while k < len(lines) and lines[k].strip() == '':
                        k += 1
                    header_line_index = None
                    p50_idx = None
                    for t in range(k, min(k + 60, len(lines))):
                        if 'p50' in lines[t]:
                            cols = [c.strip() for c in lines[t].split('|')][1:-1]
                            # locate p50 column
                            try:
                                p50_idx = next(idx for idx, c in enumerate(cols) if c.startswith('p50'))
                            except StopIteration:
                                p50_idx = None
                            header_line_index = t
                            break
                    swift_val = None
                    curr_val = None
                    if header_line_index is not None and p50_idx is not None:
                        # parse following rows to find swiftcbor and Current_run
                        for t in range(header_line_index + 1, header_line_index + 60):
                            if t >= len(lines):
                                break
                            row = lines[t]
                            if not row.strip().startswith('|'):
                                continue
                            cols = [c.strip() for c in row.split('|')][1:-1]
                            if not cols:
                                continue
                            name = cols[0]
                            # defensive check
                            if p50_idx < len(cols):
                                if 'swiftcbor' in name:
                                    swift_val = cols[p50_idx]
                                if 'Current_run' in name:
                                    curr_val = cols[p50_idx]
                            if swift_val and curr_val:
                                break
                    results[mode][bench] = (swift_val, curr_val, unit)
                    break
                j += 1
        i += 1
    return results


def clean_num(s):
    if s is None:
        return None
    s = s.strip().replace(',', '')
    # find first numeric token
    m = re.search(r"([0-9]+(?:\.[0-9]+)?)", s)
    if not m:
        return None
    try:
        return float(m.group(1))
    except:
        return None


def fmt(n):
    if n is None:
        return ''
    if n >= 1000:
        return f"{int(round(n)):,}"
    if n == int(n):
        return str(int(n))
    return f"{n:.0f}"


def render_table_section(title, rows, preferred_order=None):
    print(f"### {title} (cpu time)\n")
    print("| Benchmark | SwiftCBOR (p50) | CBOR (p50) | % Improvement |")
    print("|---|---:|---:|---:|")
    keys = []
    if preferred_order:
        for k in preferred_order:
            if k in rows:
                keys.append(k)
    # append remaining in alphabetical order
    for k in sorted(rows.keys()):
        if k not in keys:
            keys.append(k)
    for b in keys:
        s_p, c_p, unit = rows.get(b, (None, None, ''))
        sval = clean_num(s_p)
        cval = clean_num(c_p)
        s_str = (fmt(sval) + (' ' + unit if unit else '')) if sval is not None else (s_p or '')
        c_str = (fmt(cval) + (' ' + unit if unit else '')) if cval is not None else (c_p or '')
        perc = ''
        if sval is not None and cval is not None and sval != 0:
            pct = round((sval - cval) / sval * 100)
            perc = f"**{pct}%**"
        print(f"| {b} | {s_str} | {c_str} | {perc} |")
    print("\n")


def main(argv):
    parser = __import__('argparse').ArgumentParser(description='Parse Swift benchmark markdown and print compact p50 tables')
    parser.add_argument('file', nargs='?', default='-', help='Path to markdown file, or - for stdin (default)')
    args = parser.parse_args(argv)
    if args.file == '-':
        text = sys.stdin.read()
    else:
        p = Path(args.file)
        text = p.read_text()

    results = parse_markdown(text)

    # preferred orders to match your example (best-effort)
    dec_order = ["Array","Complex Object","Date","Dictionary","Double","Float","Indeterminate String","Int","Int Small","Simple Object","String","String Small"]
    enc_order = ["Array","Array Small","Bool","Complex Codable Object","Data","Data Small","Dictionary","Dictionary Small","Int","Int Small","Simple Codable Object","String","String Small"]

    render_table_section('Decoding', results.get('Decoding', {}), preferred_order=dec_order)
    render_table_section('Encoding', results.get('Encoding', {}), preferred_order=enc_order)


if __name__ == '__main__':
    main(sys.argv[1:])
