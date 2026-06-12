import SwiftUI

struct PasswordInputView: View {
    @Binding var password: String

    var body: some View {
        HStack(spacing: 12) {
            Label("Password", systemImage: "key")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 98, alignment: .leading)

            SecureField("Optional PDF open password", text: $password)
                .textFieldStyle(.roundedBorder)

            Button {
                password = ""
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
            .help("Clear password")
            .disabled(password.isEmpty)
        }
    }
}
