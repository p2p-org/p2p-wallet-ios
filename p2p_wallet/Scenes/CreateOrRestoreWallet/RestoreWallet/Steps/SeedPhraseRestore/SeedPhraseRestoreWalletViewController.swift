import AnalyticsManager
import Combine
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftUI

class SeedPhraseRestoreWalletViewModel: ObservableObject {
    var bag = Set<AnyCancellable>()

    var coordinatorIO = CoordinatorIO()

    @Injected var notificationService: NotificationService
    @Injected var clipboardManager: ClipboardManagerType
    @Injected var analyticsManager: AnalyticsManager

    // Word suggestions should appearr here
    @Published var suggestions = [String]()
    @Published var seed =
        "crowd level crater figure super canyon silver wheel release cage zoo crucial sail aerobic road awesome fatal comfort canvas obscure grow mechanic spirit pave"
    @Published var hasPasteboard: Bool = false

    func continueButtonTapped() {
        if let phrase = try? Mnemonic(phrase: seed.components(separatedBy: " ")) {
            coordinatorIO.finishedWithSeed.send(phrase.phrase)
        } else {
            // show error
            notificationService.showToast(
                title: "😔",
                text: "There isn’t a wallet with these seed phrase. Check it again"
            )
        }
    }

    func back() {
        coordinatorIO.back.send(())
    }

    func info() {
        coordinatorIO.info.send(())
    }

    func paste() {
        guard let pasteboard = clipboardManager.stringFromClipboard() else { return }
        seed = pasteboard
    }

    func clear() {
        seed = ""
    }

    init() {
        UIPasteboard.general.hasStringsPublisher.sink { val in
            self.hasPasteboard = val != nil
        }.store(in: &bag)
    }

    struct CoordinatorIO {
        var finishedWithSeed: PassthroughSubject<[String], Never> = .init()
        var back: PassthroughSubject<Void, Never> = .init()
        var info: PassthroughSubject<Void, Never> = .init()
    }
}

struct SeedPhraseRestoreWalletView: View {
//    @FocusState private var isFocused: Bool
    @ObservedObject var viewModel: SeedPhraseRestoreWalletViewModel
    @State private var seedText =
        "crowd level crater figure super canyon silver wheel release cage zoo crucial sail aerobic road awesome fatal comfort canvas obscure grow mechanic spirit pave"
    @State var isButtonEnabled = false

    init(viewModel: SeedPhraseRestoreWalletViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Enter your seed phrase")
                .apply(style: .text3)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.top, 4)
            inputView.padding(.top, 2)

            if !viewModel.suggestions.isEmpty {
                self.suggestions
            }

            Spacer()

            Group {
                TextButtonView(
                    title: "Continue",
                    style: .primary,
                    size: .large,
                    trailing: Asset.MaterialIcon.arrowForward.image,
                    onPressed: {
                        self.viewModel.continueButtonTapped()
                    }
                )
                .frame(height: 56)
            }.padding([.leading, .trailing], 20)
        }
    }

    var inputView: some View {
        VStack {
            VStack {
                HStack {
                    Text("Seed phrase")
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .padding(.top, 17)
                    Spacer()
                    HStack {
                        pasteButton
                        if !viewModel.seed.isEmpty {
                            clearButton
                                .animation(.default)
                                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.1)))
                                .padding(.leading, 5)
                        }
                    }
                    .frame(height: 32, alignment: .trailing)
                    .padding(.top, 11)
                }

//                    SeedPhraseTextView(text: self.$viewModel.seed)
//                        .frame(maxHeight: 343)

                TextEditor(text: self.$viewModel.seed)
                    .frame(maxHeight: 343)
                    .colorMultiply(Color(Asset.Colors.smoke.color))
//                        .focused($isFocused)

            }.padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        }
        .background(Color(Asset.Colors.smoke.color))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
        )
        .cornerRadius(16)
        .padding([.leading, .trailing], 16)
        .onboardingNavigationBar(title: "Restoring your wallet") {
            self.viewModel.back()
        } onInfo: {
            self.viewModel.info()
        }
    }

    var pasteButton: some View {
        Button(
            action: {
                viewModel.paste()
            },
            label: {
                HStack {
                    Image(uiImage: Asset.MaterialIcon.copy.image)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.black)
                    Text("Paste")
                        .font(uiFont: UIFont.font(of: .text4))
                        .foregroundColor(.black)
                }
            }
        )
        .frame(height: 32)
        .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 14))
        .background(viewModel.hasPasteboard ? Color(Asset.Colors.lime.color) : Color.clear)
        .cornerRadius(8)
        .fixedSize()
    }

    var clearButton: some View {
        Button(
            action: {
                viewModel.clear()
            },
            label: {
                HStack {
                    Text("Clear")
                        .font(uiFont: UIFont.font(of: .text4))
                        .foregroundColor(.black)
                    Image(uiImage: Asset.MaterialIcon.clear.image)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.black)
                }
            }
        )
        .frame(height: 32)
        .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 14))
        .background(Color(Asset.Colors.rain.color))
        .cornerRadius(8)
        .fixedSize()
    }

    var suggestions: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.suggestions, id: \.self) { word in
                self.suggestionView(with: word)
            }
        }.padding([.leading, .trailing], 16)
    }

    func suggestionView(with word: String) -> some View {
        Text(word).apply(style: .text3)
            .fixedSize(horizontal: true, vertical: true)
            .frame(maxWidth: UIScreen.main.bounds.width, minHeight: 38)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
            )
    }
}

// struct SeedPhraseTextView: UIViewRepresentable {
//
//    @Binding var text: String
//
//    func makeUIView(context: Context) -> UITextView {
//        print(context)
//        let textView = UITextView()
//    //        textView.delegate = context.coordinator
//        return textView
//    }
//
//    func updateUIView(_ uiView: UITextView, context _: Context) {
//        print(uiView)
//    //        uiView.attributedText = context.coordinator.textReducer(text: text)
//    }
//
//    typealias UIViewType = UITextView
//
//    // MARK: -
//
//    final class Coordinator: NSObject, UITextViewDelegate {
//        var text: Binding<String>
//
//        init(text: Binding<String>) {
//            self.text = text
//        }
//
//        func textViewDidChange(_ textView: UITextView) {
//            if textView.attributedText.string != text.wrappedValue.string {
//                let string = textReducer(text: textView.attributedText.string)
//                text.wrappedValue = string.string
//
//                textView.attributedText = string
//            }
//        }
//
//        //        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        //            let newText = textView.attributedText.string.
//        //            return true
//        //        }
//
//        func textReducer(text: String) -> NSMutableAttributedString {
//            let needsSpace = text.last == " "
//            let words = text
//                .components(separatedBy: CharacterSet.decimalDigits).joined(separator: " ")
//                .split(separator: " ")
//            let string = NSMutableAttributedString()
//            for (index, word) in words.enumerated() {
//                let index = NSAttributedString.attributedString(with: String(index + 1), of: .text4)
//                    .withForegroundColor(Asset.Colors.mountain.color)
//                string.append(index)
//
//                let padding4 = NSTextAttachment()
//                padding4.bounds = CGRect(x: 0, y: 0, width: 4, height: 0)
//                string.append(NSAttributedString(attachment: padding4))
//
//                let wordString = NSAttributedString.attributedString(with: String(word), of: .text3)
//                string.append(wordString)
//
//                let padding16 = NSTextAttachment()
//                padding16.bounds = CGRect(x: 0, y: 0, width: 16, height: 0)
//                string.append(NSAttributedString(attachment: padding16))
//            }
//            if needsSpace {
//                string.appending(.init(string: " "))
//            }
//
//            return string
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(text: $text)
//    }
// }

extension UIPasteboard {
    var hasStringsPublisher: AnyPublisher<Bool, Never> {
        Just(hasStrings)
            .merge(
                with: NotificationCenter.default
                    .publisher(for: UIPasteboard.changedNotification, object: self)
                    .map { _ in self.hasStrings }
            )
            .merge(
                with: NotificationCenter.default
                    .publisher(for: UIApplication.didBecomeActiveNotification, object: nil)
                    .map { _ in self.hasStrings }
            )
            .eraseToAnyPublisher()
    }
}
