---
title: Suffering with my XMonad setup in NixOS
---

I've usually setup xmonad according to the [installation guide](https://xmonad.org/INSTALL.html). I would declare either cabal or stack in my global package config. Then have it create the xmonad binary. After it creates the binary, I remove stack or cabal from my global package config. So later on when I use these build tools in specific projects, I won't be confused where it's coming from.

Recently, I tried setting up another machine and my usual setup didn't work because there were too many dependencies I had to chase down. So I decided another route and set it all up the nix way with flakes. I found [Tony Zorman's blog about a similar setup](https://tony-zorman.com/posts/xmonad-on-nixos.html). I followed every step. This would've worked if the versions matched up. I'm using nixpkgs 23.11 and I picked ghc944 as my haskell compiler. It tried to build xmonad-contrib v0.18.0 with xmonad-extras v0.17.1 which resulted in a couple of errors. 

When I see these kinds of errors, my immediate reaction is to create an overlay. So I created an overlay to try and override the version of these packages and make them match up. 

It didn't work! It still kept pulling in the same version of packages. I've deleted the derivation from the nix-store with `nix-store --delete <hash>-xmonad-extras.drv`. Even did a garbage collection with `nix-store --gc`. Nothing worked. At this point, I was so confused what was going on that I even created a patch that deletes the entire module that was being mentioned in the error just to see if it affected something. It didn't. 

I later learned that `nixpkgs.overlay` does not affect this settings. What I had to do was to declare the override in a let binding like below in my configuration.nix
```nix
{ config, pkgs, ... }: 
  let 
    compiler = "ghc944";
    hsPkgs = pkgs.haskell.packages.${compiler}.override {
      overrides = final: prev: {
        xmonad-contrib = prev.xmonad-contrib.overrideAttrs(oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "xmonad";
            repo = "xmonad-contrib";
            rev = "afd6824ce00063bb8e9b7a1c5daf0737c2f61616";
            sha256 = "1wymnq5cc55fh2v3cs8bx953y7ybi119y6f64zrrz15ac2a2vjia";
          };
        });
        xmonad-extras = prev.xmonad-extras.overrideAttrs(oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "xmonad";
            repo = "xmonad-extras";
            rev = "447842773d564ebcf238d3113c8b9f89843a7b3f";
            sha256 = "sha256-Z4JCrl3mHCF08+wKzOp3XAKKgyp4Fb55Qb3YGLwhJQM=";
          };
        });
      };
    };
  in {
  ...
```
Then in my `windowManager.xmonad`{.codeLine}, I had to assign `hsPkgs` to `windowManager.xmonad.haskellPackages`{.codeLine}. 

`sudo nixos-rebuild switch`{.codeLine} and it worked! I didn't need to declare cabal or stack in my global package config and now I can check in this setup to git. I don't need the manual step of installing and removing packages anymore!
