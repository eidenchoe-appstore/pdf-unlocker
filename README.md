# PDF Unlocker

A small macOS utility for removing PDF encryption restrictions from documents you own or are allowed to modify. Drag a PDF into the app, or choose one from Finder, and PDF Unlocker saves a new file next to the original using the `{filename}-unlock.pdf` naming pattern.

PDF Unlocker is a SwiftUI wrapper around [`qpdf`](https://qpdf.sourceforge.io/), a mature command-line PDF transformation tool. It does not crack unknown passwords. If a PDF requires an open password, enter that password in the app before unlocking.

## Features

| Feature | Details |
| --- | --- |
| Drag and drop | Drop one or more PDF files from Finder. |
| File picker | Use `Command-O` or the `Choose PDF` button. |
| Predictable output | Saves beside the source file as `{filename}-unlock.pdf`; existing files are preserved with `-unlock-2`, `-unlock-3`, and so on. |
| Optional password | Supports PDFs that require a known open password and clearly reports missing or incorrect passwords. |
| qpdf detection | Checks common Homebrew paths and the app launch environment. |
| Local-first | No upload, account, or network service is used for PDF processing. |

## Requirements

- macOS 13 Ventura or newer
- Homebrew
- qpdf

Install qpdf:

```bash
brew install qpdf
```

## Install

Download `PDFUnlocker.dmg` from the latest release, open it, and drag **PDF Unlocker.app** into **Applications**. Current release: `v0.1.3`.

If macOS warns that the app is from an unidentified developer, right-click the app in Finder, choose **Open**, and confirm once. The current local build is ad-hoc signed for direct distribution testing.

## Usage

1. Open **PDF Unlocker**.
2. Confirm the header shows `qpdf ready`.
3. Optional: enter the known PDF open password.
4. Drag a PDF into the drop zone, or click **Choose PDF**.
5. Find the unlocked copy in the same folder as the source PDF.

Example:

```text
lecture1_intro.pdf -> lecture1_intro-unlock.pdf
```

## What It Can and Cannot Do

PDF Unlocker can remove encryption restrictions when qpdf can legally transform the file, including PDFs that open normally but block copying, printing, or editing. For user-password protected PDFs, you must provide the correct password.

PDF Unlocker is not a password recovery tool. If the PDF needs an unknown password, the app reports that clearly instead of attempting recovery. Use it only for files you own, created, received with permission, or are otherwise authorized to modify.

## Build From Source

```bash
git clone https://github.com/eidenchoe-appstore/pdf-unlocker.git
cd pdf-unlocker
brew install qpdf
swift test
./script/build_and_run.sh --verify
./script/package_dmg.sh
```

The packaged app and DMG are written to `dist/`.

## Development Notes

- App source: `Sources/PDFUnlocker`
- qpdf service and naming logic: `Sources/PDFUnlockerCore`
- App icon source: `icon.icon`
- Tests: `Tests/PDFUnlockerCoreTests`
- Local run script: `script/build_and_run.sh`
- DMG packaging script: `script/package_dmg.sh`

The app resolves `qpdf` from `/opt/homebrew/bin/qpdf`, `/usr/local/bin/qpdf`, Homebrew sbin locations, and the current `PATH`.

## License

MIT. See `LICENSE`.
