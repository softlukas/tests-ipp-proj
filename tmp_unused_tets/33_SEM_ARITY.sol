class Main : Object {
    mojePlus: a a: b [
        _ := a plus: b.
    ]

    run [
        "Metóda 'mojePlus:a:' očakáva 2 argumenty, posielame len 1"
        _ := self mojePlus: 10.
    ]
}