---
title: Typescript - Organizing Modules in Vuex
---
I care about organizing folders because Javascript/Typescript doesn't have the 
convenient module system like csharp's or haskell's module system. With these
languages you can do
```csharp
// csharp
using System.Linq;
using System.Collections.Generic;
```
```haskell
-- haskell
import Control.Monad.Trans.Class
import Control.Monad.Trans.State
```
and you get the exported functions from these namespaces/modules. Unfortunately,
in Typescript I have to know the relative path.
```javascript
import { someUtilityFunction } from "../../../../../where-is-this-damn-file";
```
Initially it's just annoying but when you have hundreds of components relying on
a reusable component inside the project it becomes a mental overhead.

With Typescript projects I tend to use [barrel][barrel-files] files. Especially
projects that are enormous. It makes it a bit easier to package modules.

So I organized my vuex modules a little different from what was 
suggested in [Vuex's Application Structure][Application-Structure].

Here's a contrived example of how I organize folders.

The `action-types`{.codeLine} folder contains the actions types for the project
(e.g `const INCREMENT = "INCREMENT";`{.codeLine}). This action type will be 
used in different parts of the project depending on what will need this action type.
So I have the `action-types`{.codeLine} directory at the root level in the
`src`{.codeLine} directory. In addition to positioning this folder at the root 
level I make a barrel file for it.
```javascript
// index.ts inside action-types folder
export * from "./count.types";
```
This will `export`{.codeLine} everything in `count.types.ts`{.codeLine}.

After making the barrel file I then add it in my `tsconfig.json`{.codeLine},
in the `path`{.codeLine} field.
Like so
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/action-types": ["src/action-types"]
    }
  }
}
```
After setting up the `tsconfig.json`{.codeLine} `path`{.codeLine} field, I 
don't have to reference the relative path when I'm importing action types. 
All I have to do is this

```javascript
import { INCREMENT } from "@/action-types";
```
I import `INCREMENT`{.codeLine} like this to every file that needs this action
(e.g A Component/View that  calls an action.). So far the only time I need
to avoid this is when I'm importing from within the same parent folder.
```markdown
parent-folder
  |- child-folder-1
     |- child-1.ts
  |- child-folder-2
     |- child-2.ts
```
`child-1.ts`{.codeLine} can't do 
`import { someComponent } from "child-folder-2"`{.codeLine}. If I do this,
typescript will complain of circular dependencies.

Regarding `vuex`{.codeLine} folder organization, the `actions`{.codeLine} and `mutations`{.codeLine} 
file will stay private inside the `count`{.codeLine} folder where the
`module`{.codeLine} file is.

My overall folder structure looks like this.

```markdown
main.ts
components/
views/
action-types/
  |- count.types.ts
  |- index.ts
store/
  |- index.ts
  |- store.ts
  |- modules/
    |- index.ts
    |- count
        |- index.ts
        |- count.actions.ts
        |- count.module.ts
        |- count.mutations.ts

```

[Application-Structure]:https://vuex.vuejs.org/guide/structure.html
[barrel-files]:https://basarat.gitbooks.io/typescript/docs/tips/barrel.html
