# ``KeyAppUI/IconButton``

A button component where main focus is icon. The title is secondary.

By default it will use a ``default`` appearance for icon button.

![Conver](IconButtonStyle.png)

## Usage

Use style function to create a button with predefined appearance.

```swift
IconButton(
    image: Asset.MaterialIcon.appleLogo.image,
    title: title,
    style: .primary,
    size: .medium
).onPressed { print("tap") }
```

