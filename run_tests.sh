#!/bin/bash

# Zistí cestu k priečinku, kde sa nachádza tento skript
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Prepne pracovný adresár do priečinka skriptu
cd "$SCRIPT_DIR"

# --- KONFIGURÁCIA ---
SOL_COMPILER="../proj/sol2xml/sol_to_xml.py"
MY_INTERPRETER="../proj/python/int/src/solint.py"
TEST_DIR="./in"
REF_DIR="./ref"
OUT_DIR="./out"
DIFF_DIR="./diff"
TEMP_XML="temp_test.xml"

# Farby pre terminál
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Príprava priečinkov
mkdir -p "$OUT_DIR" "$DIFF_DIR"

if [ ! -d "$TEST_DIR" ]; then
    echo "Chyba: Adresár $TEST_DIR neexistuje!"
    exit 1
fi

echo "------------------------------------------------"
echo "Spúšťam automatizované testy SOL26"
echo "------------------------------------------------"

for test_file in "$TEST_DIR"/*.sol; do
    filename=$(basename "$test_file")
    base_name="${filename%.*}"
    
    echo -n "Testujem: $filename ... "

    # 1. KROK: Preklad do XML
    python3 "$SOL_COMPILER" "$test_file" > "$TEMP_XML" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}CHYBA PREKLADU${NC}"
        continue
    fi

    # 2. KROK: Spustenie interpreta
    python3 "$MY_INTERPRETER" -s "$TEMP_XML" > "$OUT_DIR/$base_name.out" 2>/dev/null
    actual_rc=$?

    # --- OPRAVA: Odstránenie \n na konci súboru v out/ ---
    # Použijeme perl, ktorý je na WSL/Ubuntu vždy a spoľahlivo odstráni posledný newline
    if [ -f "$OUT_DIR/$base_name.out" ]; then
        perl -i -pe 'chomp if eof' "$OUT_DIR/$base_name.out"
    fi

    # 3. KROK: Kontrola Exit kódu
    expected_rc=0
    if [ -f "$REF_DIR/$base_name.rc" ]; then
        expected_rc=$(cat "$REF_DIR/$base_name.rc" | tr -d '[:space:]')
    fi

    if [ "$actual_rc" -eq "$expected_rc" ]; then
        if [ "$actual_rc" -eq 0 ]; then
            if [ -f "$REF_DIR/$base_name.out" ]; then
                # Pridávame prepínač -Z pre diff (ignoruje rozdiely v prázdnych znakoch na konci riadku)
                diff -Z "$OUT_DIR/$base_name.out" "$REF_DIR/$base_name.out" > "$DIFF_DIR/$base_name.diff"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}PASSED${NC} (RC $actual_rc, output OK)"
                    rm -f "$DIFF_DIR/$base_name.diff"
                else
                    echo -e "${RED}FAILED${NC} (Output mismatch, check diff/)"
                fi
            else
                echo -e "${GREEN}PASSED${NC} (RC $actual_rc, no ref out)"
            fi
        else
            echo -e "${GREEN}PASSED${NC} (Expected Error $actual_rc)"
            rm -f "$OUT_DIR/$base_name.out"
        fi
    else
        echo -e "${RED}FAILED${NC} (Bad return code. Expected $expected_rc, Got $actual_rc)"
    fi

done

rm -f "$TEMP_XML"

echo "------------------------------------------------"
echo "Testovanie dokončené."