import Foundation

public enum E164Numbers {
    public static func validate(_ input: String) -> Bool {
        let regex = #"^\+[1-9]\d{1,14}$"#
        return (input.range(of: regex, options: .regularExpression)) != nil
    }
}
