---
title: Front End - My checklist in learning front end frameworks
---
After being involved in developing a big SPA<sup>&trade;</sup> I've developed a 
"To-learn" checklist when it comes to component based front end 
frameworks, which is pretty much all of them nowadays. So far this list has 
helped me with [react][react], [angular][angular], and [vue][vue].

Here they are in order:

## Directory Structure
So far this has been the most important for me. If I can organize and access 
files easily through out the project it will make the whole development process
easier because trying to figure out relative paths can become an overhead when
dealing with thousands of files, at least for me.

Since Typescript doesn't have a convenient module system out of the box. I need 
the framework to be able to accommodate [barrel][barrel-files] files. It has 
happened before where some versions of angular was not too friendly with barrel 
files but I think they've changed that because I've been using a lot of barrel 
files in an angular project and it's been working like a charm.

Typescript helps out a lot in this because in `tsconfig.json`{.codeLine}, in the 
`path`{.codeLine} field I can set a path to a directory and I can access it 
through out the project without knowing the relative path.

Here's how it looks
```json
"path": {
  "components": ["src/shared-components"]
}
```
After setting up the `path`{.codeLine} field, I can access files in 
`shared-compoents`{.codeLine} anywhere in the project like

```javascript
import { AwesomeComponent } from "components";
```
This comes really useful when you have a lot of modules accessing your local
shared components directory or any shared local directory for that matter. 
I wouldn't know how to do this in Javascript, I  probably would need to publish 
the library to [npm][npm].

## Parent-Child Component Relationship
This is when the parent and child component communicates. This is another thing
that I find important because parent components need to pass information to
their child components, and child components need to send messages to their 
respective parent component.

In [react][react] and [vue][vue], passing down information to a child component 
is in the form of `props`{.codeLine}/`@Props`{.codeLine}. In angular it will be
through the `@Input`{.codeLine} decorator. They're pretty similiar when it 
comes to passing down information but [angular][angular] is _a little bit 
diffrent_ when  it comes to the child passing it's information to the parent. In
[react][react] and [vue][vue] you'd pass a function/method to the child. In 
[angular][angular], the child emits the event then it's up to the parent which 
method to asssign to capture that event. 

Using parent-child component communication opens up to reusable components,
if your components only rely to `props`{.codeLine}, `@Input`{.codeLine}, or 
`@Props`{.codeLine} just like a function that only relies on it's arguments 
(see also [combinators][combinators]). You can reuse this component in every 
parent component that supplies that `props`{.codeLine}.

## Life Cycle
There are steps on how a component is rendered in these frameworks/library. These
steps are important to know when I start fetching data, binding data,
re-rendering the component, and if there's a behavior that needs to happen
when the component gets destroyed. These frameworks also offer more granular
life cycle hooks, these can be used if the common life cycle hooks can't handle
the use-case.

## Routing
Almost every application will have different routes to seperate information, and
the framework routing mechanism can help make it easier. Basic routing nowadays
are pretty straightforward. 

What I need to learn when it comes to routing are:

* Nested Routes
* Lazy Routing
* Nested Lazy Routing
* Route guards

A page can show different information, and sometimes I need to render some window
that can show more than one page of information inside the main page. This is
where Nested Routes comes into play.

With big applications, Lazy Routing helps in decreasing [Time to Interactive][tti]
because the application will only load the ui components that are needed 
at that moment of render, it doesn't bring in the rest of the components.

Nested Lazy routes become useful when I have nested routes that I don't want to
load if the user doesn't interactive with them.

Route guards are useful when I want to restrict users to access certain sections
of the application depending on their roles/permissions. This comes really
useful when it comes to multi-tenant applications.

## Transclusion/Multitransclusion
I think this term only gets used in [Angular][angular] from what I've seen so
far. This is component composition in react, and it's called [slots][vue-slots]
in vue. This is how it looks:

#### react

```javascript
<SplitPane right={ComponentOne} left={CompoentTwo} />
```

#### angular
```javascript
<split-pane>
  <component-one right></component-one>
  <component-one left></component-one>
</split-pane>
```

#### vue
```javascript
<split-pane>
  <component-one slot="right"></component-one>
  <component-one slot="left"></component-one>
</split-pane>
```

It's a way to compose components. This becomes really useful with reusable 
components. When this is done right, building a complex component can feel like a 
playing with legos.

## State Management
With a rich application comes state and with state comes suffering. Especially 
if it's not properly managed. So far the redux implementations have helped me. 
I've used [redux][redux] for react applications, [ngrx][ngrx] for angular, and 
recently I've been learning how to use [vuex][vuex] in a vue application. What 
I've noticed so far is if there's an atomic store that keeps track of the 
state and it's changes, a huge application is easier to manage. My biggest
complaint about redux is it's boilerplate.

## Forms
Finally, Forms! From what I've seen, `forms`{.codeLine} can be the most stateful
component when it comes to editing data because you have that intermediate state
that needs to be updated/edited then resubmitted somewhere, and that includes 
form validation. So I think there's a lot going on when it comes to forms. When
I get a handle of forms in frameworks/libraries I'll be more comfortable using 
it.

# Final thoughts
There's definitely more to learn than this list but when I can check off all 
these items I'll be comfortable with the framework, and when I go into a 
project I can hit the ground running.

[react]:https://reactjs.org/
[angular]:https://angular.io/
[vue]:https://vuejs.org/
[barrel-files]:https://basarat.gitbooks.io/typescript/docs/tips/barrel.html
[npm]:https://www.npmjs.com/
[tti]:https://developers.google.com/web/tools/lighthouse/audits/time-to-interactive
[vue-slots]:https://vuejs.org/v2/guide/components-slots.html
[redux]:https://redux.js.org/
[ngrx]:https://github.com/ngrx/platform/blob/master/docs/store/README.md
[vuex]:https://vuex.vuejs.org/
[combinators]:https://wiki.haskell.org/Combinator
