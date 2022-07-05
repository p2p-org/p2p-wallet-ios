import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        VStack {
            Text("Welcome from SwiftUI!")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding([.top, .bottom], 20)
            TextField("Username", text: $viewModel.username)
                .padding([.leading, .trailing, .bottom])
            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .padding([.leading, .trailing, .bottom])
            Text(viewModel.recommendation ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.red)
                .padding([.leading, .trailing, .bottom])
            Button("Login") {
                Task {
                    try await viewModel.login()
                }
            }
            .disabled(!viewModel.isCredentialValid)
            Spacer()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: .init())
    }
}
