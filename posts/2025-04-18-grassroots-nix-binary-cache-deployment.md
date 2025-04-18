---
title: Grassroots Nix Binary Cache Deployment
---

I've been tinkering with my github actions for my personal project and quickly found out that it takes forever to build my haskell project with nix. It takes 34 minutes to complete a build. So I looked into cachix but $50/mo is pretty steep for a side project. So I started looking into how I can host my own in a virtual machine. After some googling, I found this blog [How to set up a nix binary cache with terraform in digitalocean](https://aldoborrero.com/posts/2022/11/25/how-to-set-up-a-nix-binary-cache-with-terraform-in-digitalocean--cloudflare/). It had everything I needed! And from digitalocean's estimate it will only cost me around $5.

I pretty much followed the terraform setup from that blog. Except for the CDN with cloudflare because digitalocean spaces already has a builtin CDN. Here's how I set up my digitalocean spaces with terraform.

## Terraform

First is to declare the bucket resource. Nothing surprising here. 
```javascript
resource "digitalocean_spaces_bucket" "nix_cache" {
  name   = <cache name>
  region = "nyc3"
  acl    = "private"

  lifecycle_rule {
    id                                     = "ttl"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 1

    expiration {
      days = 7
    }
  }
}
```

Next is to create an object with some nix configuration.
```javascript
resource "digitalocean_spaces_bucket_object" "nix_cache_info" {
  region       = digitalocean_spaces_bucket.nix_cache.region
  bucket       = digitalocean_spaces_bucket.nix_cache.id
  content_type = "text/plain"
  key          = "nix-cache-info"
  content      = <<EOF
StoreDir: /nix/store
WantMassQuery: 1
Priority: 10
EOF
}
```
* `StoreDir`{.codeLine}: Specifies the directory where the Nix store is located in the system.
* `WantMassQuery`{.codeLine}: Indicates whether the cache supports bulk queries for paths. 
* `Priority`{.codeLine}: Specifies the priority of the cache when multiple caches are configured.

To configure CDN with digitalocean, declare the a cdn resource
```javascript
resource "digitalocean_cdn" "nix_cache_cdn" {
  origin = digitalocean_spaces_bucket.nix_cache.bucket_domain_name
}
```
If you want to configure it with your own domain, you can see the documentation here [DigitalOcean Spaces CDN](https://search.opentofu.org/provider/opentofu/digitalocean/latest/docs/resources/cdn)

For access policy, luckily digitalocean spaces supports aws policy format. Which I'm used to. This is how I configured my policy
```javascript
resource "digitalocean_spaces_bucket_policy" "nix_cache_access_policy" {
  region = digitalocean_spaces_bucket.nix_cache.region
  bucket = digitalocean_spaces_bucket.nix_cache.id
  policy = jsonencode({
    Id      = "DirectReads"
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowDirectReads"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${digitalocean_spaces_bucket.nix_cache.id}",
          "arn:aws:s3:::${digitalocean_spaces_bucket.nix_cache.id}/*",
        ]
        Principal = "*"
      },
      {
        Sid = "AllowAuthorizedUpdates"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${digitalocean_spaces_bucket.nix_cache.id}",
          "arn:aws:s3:::${digitalocean_spaces_bucket.nix_cache.id}/*",
        ]
        Principal = {
          "AWS" = <digitalocean spacess access key id>
        }
      }
    ]
  })
}
```
I have a policy for anonymous reads. This way I don't have to do some authentication dance when I pull from the cache from my github actions. I also have a policy for authenticated requests. This is where "grassroots" from the title comes in. I build my application locally and push the buildtime and runtime closures to my cache manually from my local machine. I do this so I know that I'm the only one pushing to my cache and I don't get any surprise bill from digitalocean.

## Github Actions
In my github actions, this is how I configured the step to pull from my self hosted cache.
```yaml
- uses: cachix/install-nix-action@v31
  with:
    github_access_token: ${{ secrets.GITHUB_TOKEN }}
    nix_path: nixpkgs=channel:nixos-unstable
    extra_nix_config: |
      substituters = <digitalocean spaces endpoint>  https://cache.nixos.org/ 
      trusted-public-keys = <nix cache public key> cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= 
```

Without the public key I would get this error. 
```bash
warning: ignoring substitute for '/nix/store/<package-name>' from '<nix cache endpoint>', as it's not signed by any of the keys in 'trusted-public-keys'
```
In order to get rid of the error above I had to sign the closures I pushed to my cache with a private key.

I obtained the private and public keys by using this command
```bash
nix-store --generate-binary-cache-key key-name <secret-key-file> <public-key-file>
```

After obtaining the keys I signed the closures with this command
```bash
nix-store --query --requisites --include-outputs $(nix build .#my-application --no-link --print-out-paths) | xargs -r -n1 nix store sign --key-file <public key>
```

Once the buildtime and runtime closures are signed, it's ready to be copied to the nix cache!
```bash
nix-store --query --requisites --include-outputs $(nix buil .#my-application --no-link --print-out-paths) | xargs -r -n1 nix copy --to 's3://<cache name>?endpoint=<region>.digitaloceanspaces.com&region=<region>' --refresh
```
Without the `--refresh`{.codeLine} flag, nix copy will not copy the paths.

## Result
After all this configuration, I've addressed my main problem of builds taking around 30 minutes to finish. Now, it only takes 8 minutes. And this without a github cache. For now, I'm good with 8 minutes.
