# MacIOS

MacIOS is an iOS build of the open-source UTM virtual-machine app, with QEMU's x86-64 system emulator. It is intended as the first practical route toward running a macOS guest on an iPhone. This is emulation; it does not boot macOS directly on iPhone hardware.

## Build the IPA

The GitHub Actions workflow checks out UTM v5.0.8 and its QEMU submodules, builds the iOS ARM64 dependencies and app on a macOS runner, changes the home-screen name to **MacIOS**, and uploads an unsigned `MacIOS.ipa` artifact.

1. Push the repository to GitHub.
2. Open **Actions → Build MacIOS → Run workflow** (or let a push start the workflow).
3. Download the **MacIOS-iOS-IPA** artifact and import `MacIOS.ipa` into LiveContainer.
4. In LiveContainer, enable **Launch with JIT** for the app and select `universal.js` as its JIT launch script. Launch the app from LiveContainer.

The first build compiles QEMU and its dependencies from source and may take a while. The workflow caches the iOS dependency sysroot for later builds.

## macOS guest status

This build provides UTM's general-purpose QEMU VM interface; it does not include macOS, an installer, an OpenCore image, Apple firmware, or ROMs. Those must be supplied separately. A Big Sur x86-64 guest will need a compatible OpenCore/UEFI setup and may be very slow because the iPhone has to emulate an x86-64 CPU in software. A successful JIT test only proves executable memory works; it does not prove that a macOS VM will boot or perform well.

The first target is to confirm that MacIOS opens, creates a basic x86-64 VM, and boots a small Linux installer. Then we can work through the Big Sur-specific boot configuration using installer files you provide.

## Upstream and licenses

MacIOS currently uses the unmodified UTM v5.0.8 iOS frontend and its QEMU fork, built from source. The app's home-screen display name is changed in the build workflow. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for upstream projects and license links.
