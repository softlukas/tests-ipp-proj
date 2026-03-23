class Main : Object {
    run [|
        "testovanie identicalTo"
        x := 5.
        y := 'text'.
        "expected False"
        _ := ((x identicalTo: y) asString) print.

        a := 5.
        b := 10.
        c := a.
        "expected True"
        _ := ((a identicalTo: c) asString) print.
        "expected False"
        _ := ((a identicalTo: b) asString) print.
    ]
}