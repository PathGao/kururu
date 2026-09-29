# App icon source

`kururu.icon` is the canonical Icon Composer document for Kururu's gray Dianlian horn spirit. Its five SVG layers retain independently editable eyes.

`AppIcon-Default.png` is the approved 1024px macOS 26 Default export from that document. After editing the Composer document, re-export it here. The build uses this export for the legacy ICNS fallback and `kururu.icon` for the adaptive asset catalog.

`Resources/Brand/logo.png` and `Resources/Brand/AppIcon-Default.png` mirror this export for documentation. Update both when replacing the export.

The menu bar and monochrome in-app marks use `Sources/Vorssaint/UI/HornSpiritMark.swift`. They intentionally omit the ripple and use transparent eye holes.
