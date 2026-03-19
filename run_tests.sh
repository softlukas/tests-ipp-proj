#!/bin/bash

# Zistí cestu k priečinku, kde sa nachádza tento skript
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# --- KONFIGURÁCIA ---
SOL_COMPILER="../proj/sol2xml/sol_to_xml.py"
MY_INTERPRETER="../proj/python/int/src/solint.py"
TEST_DIR="./in"
REF_DIR="./ref"
OUT_DIR="./out"
DIFF_DIR="./diff"
TEMP_XML="temp_test.xml"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$OUT_DIR" "$DIFF_DIR"

# --- SPRACOVANIE PARAMETROV ---
SINGLE_TEST=""
while getopts "t:" opt; do
  case $opt in
    t) SINGLE_TEST="$OPTARG" ;;
    *) echo "Použitie: $0 [-t nazov_testu.sol]"; exit 1 ;;
  esac
done

if [ -n "$SINGLE_TEST" ]; then
    # Debug mód pre jeden test
    FILES=("$TEST_DIR/$SINGLE_TEST")
    if [ ! -f "${FILES[0]}" ]; then
        echo -e "${RED}Chyba: Test súbor ${FILES[0]} neexistuje!${NC}"
        exit 1
    fi
    echo -e "${YELLOW}DEBUG MÓD: Spúšťam iba $SINGLE_TEST s viditeľným výstupom...${NC}"
else
    # Štandardný mód pre všetky testy
    FILES=("$TEST_DIR"/*.sol)
fi

echo "------------------------------------------------"
echo "Spúšťam automatizované testy SOL26"
echo "------------------------------------------------"

for test_file in "${FILES[@]}"; do
    filename=$(basename "$test_file")
    base_name="${filename%.*}"
    
    echo -n "Testujem: $filename ... "

    # 1. KROK: Preklad do XML
    # Pri debugu necháme vidieť aj chyby kompilátora
    if [ -n "$SINGLE_TEST" ]; then
        python3 "$SOL_COMPILER" "$test_file" > "$TEMP_XML"
    else
        python3 "$SOL_COMPILER" "$test_file" > "$TEMP_XML" 2>/dev/null
    fi

    if [ $? -ne 0 ]; then
        echo -e "${RED}CHYBA PREKLADU${NC}"
        continue
    fi

    # 2. KROK: Spustenie interpreta
    if [ -n "$SINGLE_TEST" ]; then
        # V debug móde: Vidíme stdout aj stderr priamo v konzole
        python3 "$MY_INTERPRETER" -s "$TEMP_XML" | tee "$OUT_DIR/$base_name.out"
        actual_rc=${PIPESTATUS[0]} # Získame RC interpreta, nie príkazu tee
    else
        # V štandardnom móde: Všetko ticho do súboru
        python3 "$MY_INTERPRETER" -s "$TEMP_XML" > "$OUT_DIR/$base_name.out" 2>/dev/null
        actual_rc=$?
    fi

    # Odstránenie \n na konci
    [ -f "$OUT_DIR/$base_name.out" ] && perl -i -pe 'chomp if eof' "$OUT_DIR/$base_name.out"

    # 3. KROK: Kontrola Exit kódu
    expected_rc=0
    [ -f "$REF_DIR/$base_name.rc" ] && expected_rc=$(cat "$REF_DIR/$base_name.rc" | tr -d '[:space:]')

    if [ "$actual_rc" -eq "$expected_rc" ]; then
        if [ "$actual_rc" -eq 0 ]; then
            if [ -f "$REF_DIR/$base_name.out" ]; then
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
        echo -e "${RED}FAILED${NC} (Expected $expected_rc, Got $actual_rc)"
    fi
done

#rm -f "$TEMP_XML"
echo "------------------------------------------------"