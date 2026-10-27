# Third-party notices

MacIOS currently builds these upstream projects from source:

- [UTM v5.0.8](https://github.com/utmapp/UTM/tree/v5.0.8), licensed under Apache License 2.0.
- [UTM's QEMU fork](https://github.com/utmapp/qemu), based on QEMU and distributed under the GNU General Public License (GPL). See the repository's `COPYING` and component license files for the applicable terms.

The build workflow changes the built app's `CFBundleDisplayName` and `CFBundleName` to `MacIOS`; it does not modify the upstream emulator source. The corresponding source is checked out at the version listed above during each build. UTM's own license and notices remain in its source tree and app bundle where packaged upstream.
