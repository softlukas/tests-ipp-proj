# Spustenie - using for python interpret only

V subore `run_test.sh` nastavte premnnu `SOL_COMPILER` na cestu k prekladacu sol -> xml ktore mame od nich.
Premennu `MY_INTERPRETER` nastavte na cestu k vasmu python interpretu.

`./run_tests.sh` vám spustí všetky testy. Pri teste `blok_jako_objekt.sol` zadajte ako input `ahoj`.

## Príklad výstupu

```
------------------------------------------------
Spúšťam automatizované testy SOL26
------------------------------------------------
Testujem: 54_instancni_atributy1.sol ... PASSED (Expected Error 54)
Testujem: 54_instancni_atributy2.sol ... PASSED (Expected Error 54)
Testujem: blok_jako_objekt.sol ... ahoj
PASSED (RC 0, output OK)
Testujem: example.sol ... PASSED (RC 0, output OK)
Testujem: vysledek_bloku.sol ... PASSED (RC 0, output OK)
------------------------------------------------
```

`./run_tests.sh -t example.sol` spusti konkretny test a v terminali bude vidiet aj debug vypisy vasho intrpreta (stderr).

Pokial by ste chceli pridat dalsi test, staci pridat subor `.sol` do zlozky `in/`, do zlozky `ref/` potom subor s rovnakym menom a priponami `.out` pre očakavany vypis a `.rc` pre exit code.



