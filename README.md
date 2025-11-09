# Forkfolio

A simple iOS app (SwiftUI + MVVM) to save and organize recipes from the web, social links, and manual entry. Local-only MVP; CloudKit sync and Share Extension can be added later.

## MVP features
- Save recipes via manual entry or pasting a URL.
- Best-effort parsing for web pages using structured data (Schema.org) and a readability fallback.
- Organize by tags/cuisine, creator, favorites.
- Search by title, ingredients, creator.
- Photos, rating, prep/cook time, servings, notes.
- Import CSV/JSON. Export as Text or Markdown.

## Structure
- iOS/Source
  - App.swift
  - Models/
  - ViewModels/
  - Views/
  - Services/
  - Resources/
- CI/
  - codemagic.yaml (template)
  - bitrise.yml (template)
- IMPORT_EXPORT.md
- ROADMAP.md

## Build
- Requires Xcode (on macOS). This repo contains source scaffolding; you can open it in Xcode and add an iOS app target if needed.
- Signing/TestFlight not configured here. Use CI templates after you regain App Store Connect access.

## Next steps
- Open on a Mac in Xcode.
- Create an iOS App target named "Forkfolio" with SwiftUI lifecycle.
- Add these source files to the target.
- Run on a simulator or device.

## Legal
- Parse only publicly available pages. Do not bypass logins or DRM.
