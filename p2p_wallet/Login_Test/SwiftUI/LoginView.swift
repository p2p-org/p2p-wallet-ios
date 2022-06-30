import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    @State var recommendation: String = "Enter credential"
    @State var isCredenticalsValid: Bool = false

    var body: some View {
        VStack {
            Text("Welcome!")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding([.top, .bottom], 20)
            TextField("Username", text: $viewModel.username)
                .padding([.leading, .trailing, .bottom])
            TextField("Password", text: $viewModel.password)
                .padding([.leading, .trailing, .bottom])
            Text(recommendation)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.red)
                .padding([.leading, .trailing, .bottom])
            Button("Login") {
                Task {
                    try await viewModel.login()
                }
            }
            .disabled(!isCredenticalsValid)
            Spacer()
        }
        .onReceive(viewModel.recommendation) { recommendation in
            self.recommendation = recommendation ?? ""
        }
        .onReceive(viewModel.isCredenticalsValid) { isCredenticalsValid in
            self.isCredenticalsValid = isCredenticalsValid
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: .init())
    }
}
