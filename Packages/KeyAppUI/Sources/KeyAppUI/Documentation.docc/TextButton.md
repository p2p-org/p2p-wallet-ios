# ``KeyAppUI/TextButton``

![Conver](TextButton.png)

## Usage

Use style function to create a button with predefined appearance.

```swift
TextButton(
    title: "Button",
    style: .primary,
    size: .medium,
    leading: nil,
    trailing: sset.MaterialIcon.arrowForward.image,
).onPressed { print("tap") }
```

