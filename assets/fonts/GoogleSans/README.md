GoogleSans font directory

This folder is intended to hold the GoogleSans font files used by the app. Add the actual font files here with the exact filenames referenced in `pubspec.yaml`:

- assets/fonts/GoogleSans/GoogleSans-Regular.ttf
- assets/fonts/GoogleSans/GoogleSans-Medium.ttf
- assets/fonts/GoogleSans/GoogleSans-Bold.ttf

How to add fonts:
- Download the TTF/OTF files and place them in this directory with the names above.

Alternative: use the `google_fonts` package instead of bundling font files.
- Add dependency: `google_fonts: ^5.0.0` (add to `pubspec.yaml` under `dependencies`).
- Use in code: `Text('Hello', style: GoogleFonts.googleSans())` — this avoids committing font binaries but requires network at build/runtime.

License note:
- Verify the font license before committing font binaries to your repository.
