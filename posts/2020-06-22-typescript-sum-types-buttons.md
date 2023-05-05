---
title: Typescript - Button Color State with ADTs
---
I've seen enough typescript code that I can say that `booleans`{.codeLine} are
over used. We need to normalize the use of sum types and reserve the use of `booleans`{.codeLine}.

There are not a lot of things that `booleans`{.codeLine} can represent. Even
something binary like the state of a light bulb can get confusing when it's
represented with a `boolean`{.codeLine}. Should `True`{.codeLine} represent the light bulb
being `off`{.codeLine} or `on`{.codeLine}, which one should `False`{.codeLine} 
represent? I'm sure with lots of comments it will be fine, but as we all know 
comments are not too effective in conveying information to other contributors.
```typescript
const toggleLightBulbState = ( lightBulbState: boolean ): boolean => {
  // if the lightbulb is on return false to turn it off.
  if ( lightBulb == true ) {
    return false;
  } 
  // otherwise turn on the light bulb.
  else {
    return true;
  }
}
```
Imagine this withtout comments, would you able able to understand what this code
is doing?

Let's go through a contrived example and deal with button color states and fake
http states, and eventually convert it to use sum types.

We'll be using [bulma][bulma] css classes in the example
```typescript
import React from "react";

const colorToClassName = ( color: string ): string => {
  if ( props.color === "blue" ) {
    return "is-info";
  } 

  else if ( props.color === "red" ) {
    return "is-danger";
  }

  else {
    return "is-warning";
  }
}

export function Button(props: { color: string }) => {
  return  <button className={ colorToClassname(color) }>Hello</button>
}
```
The parent component
```typescript
import { Button } from "./Button.tsx";

const responseToColor = ( response: string ) => string {
  if ( response === "successs" ) {
    return "blue";
  }
  else if ( response === "warning" ) {
    return "yellow";
  }
  else {
    return "red";
  }
}

export function App() {
  let httpResponse = "error";
  return (
    <div className="container">
      <div className="section">
        <Button color={responseToColor(httpResponse)} />
      </div>
    </div>
  );
}
```
Equality checks with strings is definitely error prone but it looks like this is 
fine, especially for something small scale but imagine an actual application 
with so many more cases and so much more logic. Depending on booleans and 
string equality will be a source of great agony. What can help us here is the 
type checker! Even though typescript is not as strong as something like purescript
or haskell it can still help a great deal.

With purescript we can do something like this
```haskell
-- sum type representing all possible colors this button can render
data ButtonColor
  = Blue
  | Red
  | Yellow

-- transforms ButtonColor to Bulma CSS classes.
-- Pattern match the colors and return the matching css class.
-- These bulma classes are not exposed outside this function.
colorToClassName :: ButtonColor -> String
colorToClassName = case _ of
  Blue -> "is-info"
  Red -> "is-danger"
  Yellow -> "is-warning"
```
The `ButtonColor`{.codeLine} type that represents all the possible colors the 
button can render can then be exported so it can be used in the `colorToClassName`{.codeLine}
function. With a fake http response, we can model it with a sum type and
do a case match and transform that into our button colors.
```haskell
-- type representing http response status.
data Response
  = Success
  | Error
  | Warning

-- transforms http response to button color.
responseToColor :: Response -> ButtonColor
responseToColor = case _ of
  Success -> Blue
  Error -> Red
  Warning -> Yellow
```
By using types, the purescript type checker can help us verify our program. I'm
using "verify" loosely here, I don't mean formal verification.

After that long tangent let's go back to typescript and see if we can recreate
what we did in purescript, and let's do it in react! Let's start with the button 
component and model the possible color states of this button. For a detailed
explanation on sum types in typescript, check out [Guilio Canti's
article][functional-design-adts]. In typesript, sum types are called
`discriminated unions`{.codeLine}. In order to determine which type is being
matched in a pattern match it needs a `discriminant`{.codeLine}. We'll be using
the `tag`{.codeLine} field as our `discriminant`{.codeLine}. This is used in our
"poor man's" pattern matching, which is a `switch`{.codeLine} statement.
```typescript
import React from "react";

interface Red {
  tag: "red";
}

interface Blue {
  tag: "blue";
}

interface Yellow {
  tag: "yellow";
}

export type ButtonColor
  = Red
  | Blue
  | Yellow

// poor man's pattern matching.
const toClassName = ( b: ButtonColor ): string => {
  switch ( b.tag ) {
    case "blue":
      return "is-info";

    case "red":
      return "is-danger";
    
    case "yellow":
      return "is-warning";

    default:
      return "";
  };
}

export const blue: Blue = ({ tag: "blue" });
export const red: Red = ({ tag: "red" });
export const yellow: Yellow = ({ tag: "yellow" });

export function Button (props: { color: ButtonColor }) {
  return ( <button className={ "button " + toClassName(props.color) }>Hello</button> );
}
```



Since I don't like using `switch`{.codeLine} statements, let's modify the code a little
bit using the `Option`{.codeLine} type, specifically the utility function 
`fromNullalble`{.codeLine} and it will come from the library 
[fp-ts][fp-ts]. We'll also add the `className`{.codeLine} field to the interfaces.

```typescript
import React from "react";
import { pipe } from "fp-ts/lib/function";
import { fromNullable, map, getOrElse } from "fp-ts/lib/Option";

interface Red {
  tag: "red";
  className: string;
}

interface Blue {
  tag: "blue";
  className: string;
}

interface  Yellow {
  tag: "yellow";
  className: string;
}

export interface NoColor {
  tag: "noColor";
  className: string;
}

export type ButtonColor
  = Red
  | Blue
  | Yellow
  | NoColor;

// implementation of the colors
export const blue: Blue = ({ tag: "blue", className: "is-info" });
export const red: Red = ({ tag: "red", className: "is-danger" });
export const yellow: Yellow = ({ tag: "yellow", className: "is-warning" });
export const noColor: NoColor = ({ tag: "noColor", className: "" });

interface Colors {
  blue: Blue;
  red: Red;
  yellow: Yellow;
  noColor: NoColor;
}

const colors: Colors = {
  blue,
  red,
  yellow,
  noColor
};

const toClassName = ( b: ButtonColor ): string =>
  // pattern matching
  // This "pattern matching" works because they all have the className field.
  pipe(
    fromNullable(colors[b.tag]),
    map((c: ButtonColor) => c.className),
    getOrElse(() => noColor.className)
  );

export function Button (props: { color: ButtonColor }) {
  return ( <button className={ "button " + toClassName(props.color) }>Hello</button> );
}
```
`fromNullable`{.codeLine} transforms it into an `Option`{.codeLine} type which
is another sum type with `None`{.codeLine} and `Some<A>`{.codeLine} as its inhabitants. If we access a
property that is not available in `colors`{.codeLine} it will go to the
`getOrElse`{.codeLine} function and return `noColor`{.codeLine}, otherwise it will
match a color then access the `className`{.codeLine} property. 

Now, let's look at the parent component and model the fake http response into
something we can understand or something that makes sense in the context of the
app, and transform that fake http response to a button color. 

`Success`{.codeLine}, `Error`{.codeLine}, and `Warning`{.codeLine} are the 
possible states for our fake http response here. They are then used 
in `Response`{.codeLine} to form a union of all possible states of a fake http 
response.
```typescript
import React from 'react';
import './App.css';
import {
  Button, blue, red, yellow, ButtonColor, Blue, Red, Yellow
} from "./Button";
import { pipe } from "fp-ts/lib/function";
import { fromNullable, getOrElse, map } from "fp-ts/lib/Option";

interface Success {
  tag: "success";
  color: Blue;
}

interface Error {
  tag: "error";
  color: Red;
}

interface Warning {
  tag: "warning";
  color: Yellow;
}

type Response
  = Success
  | Error
  | Warning

interface Responses {
  success: Success;
  error: Error;
  warning: Warning;
}

export const success: Success = ({ tag: "success", color: blue });
export const error: Error = ({ tag: "error", color: red });
export const warning: Warning = ({ tag: "warning", color: yellow });

const responses: Responses = {
  success,
  error,
  warning
}

const responseToColor = (res: Response): ButtonColor =>
  // pattern matching
  pipe(
    fromNullable(responses[res.tag]),
    map((r: Response) => r.color),
    getOrElse(() => red as ButtonColor) // have to tell typescript red is a member of ButtonColor
  );

export function App() {
  let fakeHttpResponse = error;
  return (
    <div className="container">
      <div className="section">
        <Button color={responseToColor(fakeHttpResponse)} />
      </div>
    </div>
  );
}
```

As a result we have eleminated `booleans`{.codeLine} in our tiny app and made
the possible states of button colors and fake http response more explicit. We 
didn't have to figure out whether `True`{.codeLine} would mean "blue", "red", 
or "yellow". We didn't have to write long comments explaining how booleans 
would represent our fake http response.

# Acknowledgements

[Functional design: Algebraic Data Types - Guilio Canti][functional-design-adts]

[fp-ts][fp-ts]

## Example Repo
[Button States](https://taezos.org/piq9117/notes-examples/src/branch/master/button-sum-types)

[functional-design-adts]:https://dev.to/gcanti/functional-design-algebraic-data-types-36kf
[fp-ts]:https://github.com/gcanti/fp-ts
[bulma]:https://bulma.io/documentation/
