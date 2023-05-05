---
title: Ocaml - Json Encoding and Decoding
---

I usually have trouble serializing/deserializing `json`{.codeLine} when I first learn a
staticly typed language. I had the same experience with C# and in Haskell. Luckily,
there's a lot of resources and it's easy to understand. This time I'm learning 
Ocaml/Bucklescript and I'm encoutering the same thing. Good thing
bucklescript's standard library provides [Js.Json][bucklescript-json].

## JSON Encoding

Creating a simple `json`{.codeLine} object.
```ocaml
let jsonPerson =
  [ ("firstName", Js.Json.string "John")
  ; ("lastName", Js.Json.string "Doe")
  ]
  |> Js.Dict.fromList
  |> Js.Json.object_

```

Creating `json`{.codeLine} from a record. First, create the record type.
```ocaml
type person = 
  { firstName : string
  ; lastName : string
  }
```
Then create a record value.
```ocaml
let personRec = 
  { firstName = "John"
  ; lastName = "Doe"
  }
```
Now, a function that will serialize the record.
```ocaml
let jsonPerson (p : person) = 
[ ("firstName", Js.Json.string p.firstName)
; ("lastName", Js.Json.string p.lastName)
]
|> Js.Dict.fromList
|> Js.Json.object_

```
To see the output in the console.
```ocaml
let _ = 
  personRec 
  |> jsonPerson 
  |> Js.log
```

## JSON Decoding
I'm gonna do the other way around in this next section. Deserializing 
`json`{.codeLine}! When I get a `json`{.codeLine} object I will transform it 
into `personRec`{.codeLine} record.

Let's say this is the `json`{.codeLine} object I get.
```ocaml
{ firstName : "John"
, lastName : "Doe"
}
```

First, I need to define a record since there's no such thing as anonymous 
records in Ocaml.
```ocaml
type person = 
{ firstName : string
; lastName : string
} [@@bs.deriving abstract]
```
I'll use `[@@bs.deriving abstract]`{.codeLine} decoractor for maninpulating 
 `json`{.codeLine} since Ocaml's data representation is not really the same 
with javascript, and also it will give me convenience functions to access the 
fields.

I'll create a utility function to help me extract json.
```ocaml
let extractField field jsonDict =
  let open Belt_Option in
  let id a = a in
    flatMap
      (Js.Dict.get jsonDict field)
      Js.Json.decodeString
    |> (function o -> mapWithDefault o "" id)
```
This will be my main decoding function
```ocaml
let jsonToPerson json =
  match Js.Json.decodeObject json with
  | Some j ->
    personRec
      ~firstName:(extractField "firstName" j)
      ~lastName:(extractField "lastName" j)
  | None ->
    personRec
      ~firstName:""
      ~lastName:""
```
To simulate a `json`{.codeLine} object I'll make `jsonPerosn`{.codeLine}.
```ocaml
let jsonPerson =
  [ ("firstName", Js.Json.string "John")
  ; ("lastName", Js.Json.string "Doe")
  ]
  |> Js.Dict.fromList
  |> Js.Json.object_
```
To view the output
```ocaml
let _ = 
  person 
  |> jsonToPerson 
  |> Js.log
```

## Using [bs-json][bs-json]

### JSON Encoding 

I'll encode a record using bs-json to turn it into a `json`{.codeLine} object.
First, I'll create the record type.
```ocaml
type person = 
{ firstName : string
; lastName : string
}
```
Then, the record itself.
```ocaml
let personRec =
{ firstName = "John"
; lastName = "Doe"
}
```
Next, will be the function to create the `json`{.codeLine} object from the 
record
```ocaml
let jsonPerson (p : person) =
  let open Json.Encode in
    object_
      [ ("firstName", string p.firstName)
      ; ("lastName", string p.lastName)
      ]
```
To view the output in the console.
```ocaml
let _ = 
  personRec 
  |> jsonPerson 
  |> Js.log
```

### JSON Decoding 
I'm expecting the same `json`{.codeLine} from above.
```ocaml
{ firstName : "John"
, lastName : "Doe"
}
```

Define the `person`{.codeLine} record.
```ocaml
type person =
{ firstName : string
; lastName : string
} [@@bs.deriving abstract]
```

Then, the function to transform the record to a `json`{.codeLine} object.
```ocaml
let jsonToPerson json =
  let open Json.Decode in
    person
    ~firstName:(json |> (field "firstName" string))
    ~lastName:(json |> (field "lastName" string))

```
To see the output in the console
```ocaml
let _ =
  jsonPerson
  |> jsonToPerson
  |> Js.log
```
[bucklescript-api]:https://bucklescript.github.io/bucklescript/api/
[bucklescript-json]:https://bucklescript.github.io/bucklescript/api/Js_json.html
[bs-json]:https://github.com/glennsl/bs-json
