#!/usr/bin/env python3
import argparse
import csv
import re
from pathlib import Path
from typing import Iterable, Tuple, Set, List


REF_REGEX = re.compile(r"\bref=([A-Z0-9]{6,12})\b")
ID_REGEX = re.compile(r"\bid=(\d{6,20})\b")
# Прямые пары вида CODE:ID (например, TXD2KQE0:6358105675)
PAIR_REGEX = re.compile(r"^\s*([A-Z0-9]{6,12})\s*:\s*(\d{6,20})\s*$")


def extract_pairs_from_logs(lines: Iterable[str]) -> Set[Tuple[str, str]]:
    pairs: Set[Tuple[str, str]] = set()
    for line in lines:
        if "ref=" not in line or "id=" not in line:
            continue
        ref_match = REF_REGEX.search(line)
        id_match = ID_REGEX.search(line)
        if not ref_match or not id_match:
            continue
        referral_code = ref_match.group(1).strip()
        telegram_id = id_match.group(1).strip()
        if referral_code and telegram_id:
            pairs.add((telegram_id, referral_code))
    return pairs


def extract_pairs_from_code_id_lines(lines: Iterable[str]) -> Set[Tuple[str, str]]:
    pairs: Set[Tuple[str, str]] = set()
    for line in lines:
        m = PAIR_REGEX.match(line)
        if not m:
            continue
        code, tid = m.group(1).strip().upper(), m.group(2).strip()
        pairs.add((tid, code))
    return pairs


def main() -> None:
    parser = argparse.ArgumentParser(description="Parse Telegram data and extract (telegram_id, referral_code) pairs.")
    parser.add_argument(
        "--input",
        required=True,
        help="Path to the raw log file (UTF-8)",
    )
    parser.add_argument(
        "--output",
        default="logs/referral_pairs.csv",
        help="Output CSV path with header: referred_telegram_id,referral_code",
    )
    parser.add_argument(
        "--format",
        choices=["auto", "logs", "pairs"],
        default="auto",
        help="Input format: 'logs' for lines with id=/ref=, 'pairs' for CODE:ID, or 'auto' to detect",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with input_path.open("r", encoding="utf-8", errors="ignore") as f:
        lines: List[str] = [ln.rstrip("\n") for ln in f]

    if args.format == "logs":
        pairs = extract_pairs_from_logs(lines)
    elif args.format == "pairs":
        pairs = extract_pairs_from_code_id_lines(lines)
    else:
        # auto-detect: сначала ищем прямые пары CODE:ID, иначе парсим как логи
        if any(PAIR_REGEX.match(ln) for ln in lines):
            pairs = extract_pairs_from_code_id_lines(lines)
        else:
            pairs = extract_pairs_from_logs(lines)

    # Write deduplicated, stable order by telegram_id then referral_code
    sorted_pairs = sorted(pairs, key=lambda x: (int(x[0]), x[1]))
    with output_path.open("w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["referred_telegram_id", "referral_code"]) 
        writer.writerows(sorted_pairs)

    print(f"Wrote {len(sorted_pairs)} pairs to {output_path}")


if __name__ == "__main__":
    main()

