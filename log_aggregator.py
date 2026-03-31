#!/usr/bin/env python3
"""
Advanced consolidated logger for FlutterPy Chat.
Aggregates logs from all 4 layers, displays with timestamps/colors, and saves to file.

Usage:
    python3 log_aggregator.py              # Display in console with color
    python3 log_aggregator.py --file       # Also save to debug_logs.txt
    python3 log_aggregator.py --follow     # Tail-like continuous display
"""

import subprocess
import sys
import re
from datetime import datetime
from pathlib import Path

# ANSI color codes
COLORS = {
    "[ChatScreen]": "\033[92m",  # Green - Flutter UI
    "[PythonChatBridge]": "\033[94m",  # Blue - Dart service
    "[PythonBridge]": "\033[95m",  # Magenta - Kotlin platform
    "[chatbot_engine]": "\033[93m",  # Yellow - Python backend
    "RESET": "\033[0m",
    "BOLD": "\033[1m",
    "DIM": "\033[2m",
}

LAYER_DESCRIPTIONS = {
    "[ChatScreen]": "Flutter UI",
    "[PythonChatBridge]": "Dart Service",
    "[PythonBridge]": "Kotlin Platform",
    "[chatbot_engine]": "Python Backend",
}


def print_header():
    """Print fancy header."""
    print(f"{COLORS['BOLD']}\n{'='*70}{COLORS['RESET']}")
    print(
        f"{COLORS['BOLD']}  FlutterPy Chat - Consolidated Debug Logger{COLORS['RESET']}"
    )
    print(f"{COLORS['BOLD']}{'='*70}{COLORS['RESET']}\n")

    print("Layer Color Legend:")
    for tag, color in COLORS.items():
        if tag not in ["RESET", "BOLD", "DIM"] and tag in LAYER_DESCRIPTIONS:
            print(f"  {color}{tag:25} {LAYER_DESCRIPTIONS[tag]}{COLORS['RESET']}")

    print(
        f"\n{COLORS['DIM']}Starting log stream... (Ctrl+C to exit){COLORS['RESET']}\n"
    )
    print(f"{COLORS['DIM']}{'-'*70}{COLORS['RESET']}\n")


def colorize_line(line):
    """Colorize a log line based on tag."""
    for tag, color in COLORS.items():
        if tag not in ["RESET", "BOLD", "DIM"] and tag in line:
            # Extract timestamp if present
            match = re.search(r"(\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+)", line)
            timestamp = match.group(1) if match else ""

            if timestamp:
                return f"{COLORS['DIM']}{timestamp}{COLORS['RESET']} {color}{line}{COLORS['RESET']}"
            else:
                return f"{color}{line}{COLORS['RESET']}"
    return line


def filter_logs():
    """Read from adb logcat and filter relevant logs."""
    try:
        # Build grep pattern to match all tags
        grep_pattern = (
            r"\[ChatScreen\]|\[PythonChatBridge\]|\[PythonBridge\]|\[chatbot_engine\]"
        )

        # Run adb logcat with grep
        process = subprocess.Popen(
            ["adb", "logcat"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            bufsize=1,
        )

        # Filter and display lines
        for line in process.stdout:
            line = line.rstrip("\n")
            if re.search(grep_pattern, line):
                colored_line = colorize_line(line)
                print(colored_line)

                # Optionally write to file
                if "--file" in sys.argv:
                    with open("debug_logs.txt", "a") as f:
                        f.write(f"{line}\n")

    except KeyboardInterrupt:
        print(f"\n\n{COLORS['DIM']}{'-'*70}{COLORS['RESET']}")
        print(f"{COLORS['BOLD']}Log capture stopped.{COLORS['RESET']}")
        if "--file" in sys.argv:
            print(f"Logs saved to: {Path('debug_logs.txt').absolute()}")
        sys.exit(0)
    except FileNotFoundError:
        print(
            f"{COLORS['BOLD']}\033[91mError: adb not found. Make sure Android SDK is installed.{COLORS['RESET']}"
        )
        sys.exit(1)


def main():
    """Main entry point."""
    # Clear screen
    print("\033[2J\033[H", end="")

    print_header()

    # Clear old log file if starting fresh
    if "--file" in sys.argv and Path("debug_logs.txt").exists():
        Path("debug_logs.txt").unlink()

    filter_logs()


if __name__ == "__main__":
    main()
