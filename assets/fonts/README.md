Google Sans font files

This folder should contain the Google Sans font files used by the app. The repository intentionally does not include the font binaries (check licensing and download sources before adding).

Expected filenames (as referenced in `pubspec.yaml`):

- GoogleSans-Regular.ttf   (weight: 400)
- GoogleSans-Medium.ttf    (weight: 500)
- GoogleSans-Bold.ttf      (weight: 700)

Where to get the fonts:
- Google Sans is distributed by Google. If you have a license or a permitted source, download the TTF files and place them here.
- Alternatively you can use the "Product Sans" or other Google proprietary fonts only if you have the right to do so. For open-source usage prefer fonts under the SIL or OFL license.

How to add the files:
1. Download the three TTF files and copy them into this folder (`assets/fonts/`).
2. Verify the filenames match the list above.
3. From the project root run:

   flutter pub get

4. Rebuild the app (for example, `flutter run` or via your IDE).

Sample pubspec snippet (already added to `pubspec.yaml`):

flutter:
  fonts:
    - family: GoogleSans
      fonts:
        - asset: assets/fonts/GoogleSans-Regular.ttf
          weight: 400
        - asset: assets/fonts/GoogleSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/GoogleSans-Bold.ttf
          weight: 700

License note:
- Ensure you comply with the font's license before committing binaries into the repo. If the font is not allowed to be committed, keep these files locally or use a CI step to inject them at build time.
