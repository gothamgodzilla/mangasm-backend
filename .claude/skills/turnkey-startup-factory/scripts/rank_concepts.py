#!/usr/bin/env python3
"""Rank startup concepts using the Turnkey Startup Factory scorecard."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

WEIGHTS = {"profit": 0.40, "popularity": 0.35, "ease": 0.25}
CONFIDENCE_ORDER = {"low": 0, "medium": 1, "high": 2}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Rank startup concepts by 40% profit, 35% popularity, and 25% ease; "
            "then evaluate the Turnkey Startup Factory build gate."
        )
    )
    parser.add_argument("input", type=Path, help="JSON file containing a list of candidate objects")
    parser.add_argument("-o", "--output", type=Path, help="Write ranked JSON to this path; otherwise print to stdout")
    return parser.parse_args()


def validate_score(value: Any, field: str, candidate_name: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{candidate_name}: {field} must be numeric")
    score = float(value)
    if score < 1 or score > 10:
        raise ValueError(f"{candidate_name}: {field} must be between 1 and 10")
    return score


def normalize_confidence(value: Any, candidate_name: str) -> dict[str, str]:
    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized not in CONFIDENCE_ORDER:
            raise ValueError(f"{candidate_name}: confidence must be low, medium, or high")
        return {key: normalized for key in WEIGHTS}

    if not isinstance(value, dict):
        raise ValueError(f"{candidate_name}: confidence must be a string or an object")

    result: dict[str, str] = {}
    for key in WEIGHTS:
        normalized = str(value.get(key, "low")).strip().lower()
        if normalized not in CONFIDENCE_ORDER:
            raise ValueError(f"{candidate_name}: confidence.{key} must be low, medium, or high")
        result[key] = normalized
    return result


def rank_candidate(raw: dict[str, Any]) -> dict[str, Any]:
    name = str(raw.get("name", "")).strip()
    if not name:
        raise ValueError("Every candidate requires a non-empty name")

    scores = {key: validate_score(raw.get(key), key, name) for key in WEIGHTS}
    confidence = normalize_confidence(raw.get("confidence", "low"), name)
    composite = round(sum(scores[key] * WEIGHTS[key] for key in WEIGHTS), 2)
    confidence_passes = sum(CONFIDENCE_ORDER[value] >= 1 for value in confidence.values()) >= 2

    checks = {
        "composite_at_least_7": composite >= 7.0,
        "no_category_below_6": min(scores.values()) >= 6.0,
        "two_categories_medium_or_high_confidence": confidence_passes,
        "buyer_clear": bool(raw.get("buyer_clear", False)),
        "validation_feasible": bool(raw.get("validation_feasible", False)),
        "no_fatal_risk": not bool(raw.get("fatal_risk", False)),
    }
    gate_passed = all(checks.values())

    result = dict(raw)
    result.update(scores)
    result["confidence"] = confidence
    result["composite"] = composite
    result["gate_checks"] = checks
    result["gate_passed"] = gate_passed
    result["verdict"] = "build" if gate_passed else "validate"
    return result


def confidence_sort_value(candidate: dict[str, Any]) -> int:
    return sum(CONFIDENCE_ORDER[value] for value in candidate["confidence"].values())


def main() -> int:
    args = parse_args()
    try:
        raw_data = json.loads(args.input.read_text(encoding="utf-8"))
        if not isinstance(raw_data, list) or not raw_data:
            raise ValueError("Input JSON must be a non-empty list of candidate objects")
        if not all(isinstance(item, dict) for item in raw_data):
            raise ValueError("Each candidate must be a JSON object")

        ranked = [rank_candidate(item) for item in raw_data]
        ranked.sort(
            key=lambda item: (
                item["composite"],
                confidence_sort_value(item),
                item["profit"],
                -float(item.get("validation_cost", 0) or 0),
                -float(item.get("regulatory_burden", 0) or 0),
            ),
            reverse=True,
        )
        for index, item in enumerate(ranked, start=1):
            item["rank"] = index

        output = json.dumps(ranked, indent=2, ensure_ascii=False) + "\n"
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(output, encoding="utf-8")
        else:
            sys.stdout.write(output)
        return 0
    except (OSError, json.JSONDecodeError, ValueError, TypeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
