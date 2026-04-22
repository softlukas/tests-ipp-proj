#!/usr/bin/env python3
"""
Script to parse test results from report.json and display them in a readable table format.
"""

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Tuple
from dataclasses import dataclass


@dataclass
class TestResult:
    name: str
    category: str
    status: str  # "PASS" or "FAIL"
    error_message: str = ""
    error_details: dict = None


def parse_report(report_file: Path) -> List[TestResult]:
    """Parse report.json and extract test results."""
    
    with open(report_file, 'r', encoding='utf-8') as f:
        report = json.load(f)
    
    results = []
    test_results_by_category = report.get('results', {})
    
    # Process results for each category
    for category_name, category_data in test_results_by_category.items():
        # Skip if not a dict
        if not isinstance(category_data, dict):
            continue
        
        # Access the test_results field within each category
        tests_in_category = category_data.get('test_results', {})
        
        if not isinstance(tests_in_category, dict):
            continue
        
        for test_name, test_case_report in tests_in_category.items():
            if not isinstance(test_case_report, dict):
                continue
            
            # The 'result' field contains the test status (passed, parse_fail, int_fail, diff_fail)
            result_status = test_case_report.get('result', 'unknown')
            status = "PASS" if result_status == 'passed' else "FAIL"
            error_msg = ""
            error_details = {}
            
            if result_status != 'passed':
                # Build error message based on result type
                if result_status == 'parse_fail':
                    parser_exit = test_case_report.get('parser_exit_code')
                    error_msg = "bad exit"
                    error_details = {
                        'type': 'parse_fail',
                        'parser_exit_code': parser_exit,
                        'parser_stderr': test_case_report.get('parser_stderr', '')
                    }
                elif result_status == 'int_fail':
                    int_exit = test_case_report.get('interpreter_exit_code')
                    error_msg = "bad exit"
                    error_details = {
                        'type': 'int_fail',
                        'interpreter_exit_code': int_exit,
                        'interpreter_stderr': test_case_report.get('interpreter_stderr', '')
                    }
                elif result_status == 'diff_fail':
                    error_msg = "diff mismatch"
                    error_details = {
                        'type': 'diff_fail',
                        'expected_stdout': test_case_report.get('parser_stdout', ''),
                        'actual_stdout': test_case_report.get('interpreter_stdout', '')
                    }
            
            results.append(TestResult(
                name=test_name,
                category=category_name,
                status=status,
                error_message=error_msg,
                error_details=error_details if error_details else None
            ))
    
    return results


def print_table(results: List[TestResult], show_stderr: bool = False) -> None:
    """Print results in a formatted table."""
    
    if not results:
        print("No test results found.")
        return
    
    # Sort by category and name
    results.sort(key=lambda x: (x.category, x.name))
    
    # Print header
    print(f"{'Status':<8} {'Test Name':<30} {'Category':<25} Message")
    print("-" * 100)
    
    # Print rows
    current_category = None
    for result in results:
        # Add separator between categories
        if current_category != result.category:
            if current_category is not None:
                print("-" * 100)
            current_category = result.category
        
        # Status symbol
        status_symbol = "🟢 ✓" if result.status == "PASS" else "🔴 ✗"
        
        # Build the main line
        main_line = f"{status_symbol:<8} {result.name:<30} {result.category:<25} {result.error_message}"
        print(main_line)
        
        # Print error details if present and not passing
        if result.status == "FAIL" and result.error_details:
            details = result.error_details
            if details.get('type') == 'parse_fail':
                parser_exit = details.get('parser_exit_code')
                print(f"         └─ bad exit: {parser_exit}")
                if show_stderr and details.get('parser_stderr'):
                    stderr_text = details['parser_stderr'][:80]
                    print(f"            parser stderr: {stderr_text}")
            elif details.get('type') == 'int_fail':
                int_exit = details.get('interpreter_exit_code')
                print(f"         └─ bad exit: {int_exit}")
                if show_stderr and details.get('interpreter_stderr'):
                    stderr_text = details['interpreter_stderr'][:80]
                    print(f"            interpreter stderr: {stderr_text}")
            elif details.get('type') == 'diff_fail':
                actual = details.get('actual_stdout', '')[:80]
                print(f"         └─ interpreter_stdout: {actual}")
    
    # Print summary
    print("-" * 100)
    passed = sum(1 for r in results if r.status == "PASS")
    failed = sum(1 for r in results if r.status == "FAIL")
    total = len(results)
    success_rate = (100 * passed // total) if total > 0 else 0
    print(f"\n✓ {passed} passed | ✗ {failed} failed | Total: {total} tests | Success: {success_rate}%")


def main():
    """Main entry point."""
    
    parser = argparse.ArgumentParser(
        description="Parse SOL26 test report and display results"
    )
    parser.add_argument(
        'report_file',
        type=Path,
        help='Path to the report.json file'
    )
    parser.add_argument(
        '-e', '--stderr',
        action='store_true',
        help='Show interpreter/parser stderr details'
    )
    
    args = parser.parse_args()
    
    report_file = args.report_file
    
    if not report_file.exists():
        print(f"Error: Report file '{report_file}' not found.")
        sys.exit(1)
    
    try:
        results = parse_report(report_file)
        print_table(results, show_stderr=args.stderr)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
