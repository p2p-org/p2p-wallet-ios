# ``KeyAppUI/SplashViewController``

A viewController with splash animation for app openning.

## Usage

Initialize controller and present it the way you need.

```swift
let splashVC = SplashViewController()
present(splashVC, animated: true)
```swift

Currently animation is not infinite. It plays one time and the screen will close itself. The behaviour will be changed as soon as onboarding will be released.
