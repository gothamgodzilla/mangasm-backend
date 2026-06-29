# Mangasm — Project Map

One reference so accounts, repos, keys, and emails never get tangled.

## The two identities that matter (and never touch each other)

```
APPLE (App Store)  →  Dicklicious@icloud.com   ·  Apple Team ID 9SCVWDNBJ8
                      The ONLY identity the App Store cares about.
                      Lives in: Xcode → Settings → Accounts, and App Store Connect.

GITHUB (code)      →  gothamgodzilla   ("Mangasm Enterprises")
                      Your main personal login. Logged into Xcode for source control.
                      Has ZERO effect on App Store submission.
```

## Repos — everything Mangasm lives under `gothamgodzilla`

```
gothamgodzilla/Mangasm           →  iOS app (SwiftUI). Xcode pushes here.
gothamgodzilla/mangasm-backend   →  Supabase backend (this repo): migrations,
                                    RLS, edge functions, CI.
```

`drama-llama-org` is a **separate** account that briefly hosted a staging copy of
the backend. Ignore or delete it — nothing depends on it.

> Note: there is **no "Mangasmic" org**. An earlier AI session invented that name.
> Your account is `gothamgodzilla`.

## How the app reaches the backend

Not via GitHub. The iOS app connects to Supabase with the **project URL + anon
key** stored in a gitignored `Config.xcconfig` (referenced from `Info.plist`).
The **service-role key never ships in the app** — it belongs only in edge
functions / server env.

## Keeping two GitHub accounts straight on one Mac

Per-folder identity in `~/.gitconfig`:

```
[includeIf "gitdir:~/Developer/mangasm/"]
    path = ~/.gitconfig-gotham
```

…and `~/.gitconfig-gotham` sets the `gothamgodzilla` name/email. Then always
`git remote -v` before pushing an unfamiliar repo.

## Security TODO (from leaked secrets in an old chat)

- [ ] Rotate the GitHub Personal Access Token.
- [ ] Rotate the Supabase keys (anon + service-role).
- [ ] Confirm no real keys are committed (they should live in `Config.xcconfig`
      / `supabase/.env.local`, both gitignored).

## The one rule

**Everything Mangasm → `gothamgodzilla`. App Store → `Dicklicious@icloud.com`.**
They are independent. Neither can break the other.
