# Current brand assets

The current mark is the kururu octopus. `logo.png` and `AppIcon-Default.png` are the same application icon with its existing light-gray badge background. The SVG inside `AppIcon.icon` also contains the octopus; its historical filename is retained for the existing Icon Composer reference.

`build.sh` generates the shipping icon directly from `Sources/Vorssaint/UI/OctopusMark.swift` with `Tools/MakeIcon.swift`. This legacy `AppIcon.icon` document is not the shipping source. Do not restore its former upstream artwork.

All sizes use the menu-bar head proportions: horizontal scale 1.28, vertical scale 1.10, and vertical offset -1.6 in the original coordinate system. Arms keep their original coordinates. The same transformation is present in the mascot SVG and animation page.

To regenerate the PNG assets from native geometry:

```sh
mkdir -p .build/brand
swiftc Sources/Vorssaint/UI/OctopusMark.swift Tools/MakeIcon.swift -o .build/brand/MakeIcon
.build/brand/MakeIcon .build/brand/AppIcon.iconset
cp .build/brand/AppIcon.iconset/icon_512x512@2x.png Resources/Brand/AppIcon-Default.png
cp .build/brand/AppIcon.iconset/icon_512x512@2x.png Resources/Brand/logo.png
cp .build/brand/OctopusArtwork.png assets/mascots/octopus/mark.png
```

Historical screenshots remain historical records and are not regenerated.
