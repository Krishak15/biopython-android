#!/bin/bash

# Consolidated debug logger for FlutterPy Chat
# Aggregates logs from all 4 layers: Flutter, Kotlin, Python bridge, Python engine
# Run: ./debug_logs.sh

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  FlutterPy Chat - Consolidated Debug Logger${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Color coding:"
echo -e "  ${GREEN}[ChatScreen]${NC}         = Flutter UI layer"
echo -e "  ${BLUE}[PythonChatBridge]${NC}   = Dart service layer"
echo -e "  ${PURPLE}[PythonBridge]${NC}      = Kotlin platform layer"
echo -e "  ${YELLOW}[chatbot_engine]${NC}    = Python backend layer"
echo ""
echo -e "${CYAN}Starting real-time log stream... (Ctrl+C to stop)${NC}"
echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
echo ""

# Function to colorize logs by tag
colorize_logs() {
    while IFS= read -r line; do
        if [[ $line == *"[ChatScreen]"* ]]; then
            echo -e "${GREEN}${line}${NC}"
        elif [[ $line == *"[PythonChatBridge]"* ]]; then
            echo -e "${BLUE}${line}${NC}"
        elif [[ $line == *"[PythonBridge]"* ]]; then
            echo -e "${PURPLE}${line}${NC}"
        elif [[ $line == *"[chatbot_engine]"* ]]; then
            echo -e "${YELLOW}${line}${NC}"
        else
            echo "$line"
        fi
    done
}

# Run logcat with pattern matching and colorize
adb -s 192.168.1.33:35975 logcat | grep -E "\[ChatScreen\]|\[PythonChatBridge\]|\[PythonBridge\]|\[chatbot_engine\]" | colorize_logs
