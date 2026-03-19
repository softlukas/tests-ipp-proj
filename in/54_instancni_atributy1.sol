class Main : Object {
run [|
"definuje a inicializuje instanční atribut 'value'"
r := self value: 10.
"definuje další inst. atribut 'next', inicializuje hodnotou atributu 'value'"
e := self next: (self value).
"atribut 'value' již existuje, takže pouze modifikuje hodnotu na nil"
t := self value: nil.
"CHYBA 54! Třída definuje metodu foo, jméno nelze použít jako atribut."
_ := self foo: 10.
]
foo [|]
}