---
title: Nix - Calling a project with a flake file
---

It hasn't been that long since I've been using flakes, and only recently started looking into consuming projects that are using flakes. I'm used to consuming projects with nix derivation files in them and using `callPackage`{.codeLine} on them but I had no clue on how to do it on projects with flake files. I don't think there's a place where nix documentation is consolidated so I googled "How to use nix callPackage on a project with a flake file". To no one's surprise, it didn't return anything useful. Sure, it returned a lot of results about nix flake tutorial but nothing in the first page about consuming a project that is using a nix flakes, and of course I didn't go beyond the first page of google results. I imagine beyond the first page of google search result is where you'll find [the backrooms][backrooms]

My second attempt at seeking help was the nix discord, but all I got was 

> Just use callPackage then. 

Thank you, that was very helpful.

Thankfully [chatgpt][chatgpt] came in to the rescue and provided me with the answer that I needed. It's suggestion was to use 
```nix
builtins.getFlake "<repository url and revision>"
```

So this is what I did for my overlay
```nix

self: super: {
  hsPkgs = super.haskell.packages.ghc944.override { 
    overrides = hself: hsuper: {
      tie = (builtins.getFlake "github:piq9117/tie/b53c3f909a70ff5576734d0d668b62951d117972").outputs.packages.${self.stdenv.hostPlatform.system}.default;
      ...
    };
  };
}
```

I built it with `nix build`{.codeLine}. A few seconds later out my `result`{.codeLine} directory. Success!


[backrooms]:https://youtu.be/H4dGpz6cnHo
[chatgpt]:https://openai.com/blog/chatgpt
