//
//  ChangePinView.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/28/26.
//

import SwiftUI

struct ChangePinView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthStorageViewModel

    @State private var currentPin: String = ""
    @State private var newPin: String = ""
    @State private var confirmPin: String = ""
    @State private var message: String = "Enter your current PIN before choosing a new one."
    @State private var hasError: Bool = false
    @State private var pinChangeAttempts: Int = 0
    @FocusState private var focusedField: ChangePinFocusField?

    private var canSubmit: Bool {
        self.currentPin.count == 6 &&
        self.newPin.count == 6 &&
        self.confirmPin.count == 6
    }

    private var pinProgress: String {
        "\(self.newPin.count)/6"
    }

    var body: some View {
        VStack(spacing: 0) {
            UniversalHeader(header: {
                Text("Change PIN")
                    .default_header()
            }) {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.c1_text)
                }
                .padding(7)
                .applyLiquidGlassIfSupported(shape: .circle, color: Color.c1_accent, isInteractive: true)
            } trailing_button: {
                EmptyView()
            }

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        Image(systemName: "key.shield.fill")
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.c1_primary)
                            .frame(width: 84, height: 84)
                            .background(
                                Circle()
                                    .fill(Color.c1_secondary.opacity(0.75))
                            )

                        Text("Update your vault PIN")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.c1_text)

                        Text("Use a 6-digit PIN you can remember. Your existing PIN is required before PhotoSafe saves the new one.")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.c1_text.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.top, 22)

                    VStack(spacing: 14) {
                        PinEntryField(
                            title: "Current PIN",
                            subtitle: "Confirm it is really you",
                            text: self.$currentPin,
                            field: .currentPin,
                            focusedField: self.$focusedField
                        )

                        Divider()
                            .background(Color.c1_text.opacity(0.25))

                        PinEntryField(
                            title: "New PIN",
                            subtitle: "Must be 6 digits",
                            text: self.$newPin,
                            //trailingText: self.pinProgress,
                            field: .newPin,
                            focusedField: self.$focusedField
                        )

                        PinEntryField(
                            title: "Confirm New PIN",
                            subtitle: "Re-enter the new PIN",
                            text: self.$confirmPin,
                            field: .confirmPin,
                            focusedField: self.$focusedField
                        )
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.c1_secondary.opacity(0.75))
                    )

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: self.hasError ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(self.hasError ? .red : Color.c1_primary)

                        Text(self.message)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.c1_text.opacity(0.78))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(13)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill((self.hasError ? Color.red : Color.c1_secondary).opacity(0.24))
                    )

                    Button {
                        self.changePin()
                    } label: {
                        Text("Save New PIN")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.c1_text)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.c1_accent)
                            )
                    }
                    .disabled(!self.canSubmit)
                    .opacity(self.canSubmit ? 1 : 0.45)
                }
                .padding(.horizontal)
                .padding(.bottom, 28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.c1_background)
        .navigationBarBackButtonHidden(true)
        .sensoryFeedback(trigger: self.pinChangeAttempts) { oldValue, newValue in
            newValue > oldValue ? .impact(weight: .heavy, intensity: 1.0) : nil
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    self.focusedField = nil
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
        }
        .onChange(of: self.currentPin) { _, newValue in
            if newValue.count == 6 {
                self.focusedField = .newPin
            }
        }
        .onChange(of: self.newPin) { _, newValue in
            if newValue.count == 6 {
                self.focusedField = .confirmPin
            }
        }
        .onChange(of: self.confirmPin) { _, newValue in
            if newValue.count == 6 {
                self.focusedField = nil
            }
        }
    }

    private func changePin() {
        switch self.authViewModel.changePin(
            currentPin: self.currentPin,
            newPin: self.newPin,
            confirmPin: self.confirmPin
        ) {
        case .success:
            self.hasError = false
            self.message = "Your PIN was updated."
            self.currentPin = ""
            self.newPin = ""
            self.confirmPin = ""

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.dismiss()
            }
        case .currentPinIncorrect:
            self.showError("Current PIN is incorrect.")
            self.currentPin = ""
        case .invalidNewPin:
            self.showError("Each PIN field must contain exactly 6 digits.")
        case .pinMismatch:
            self.showError("New PIN and confirmation do not match.")
            self.confirmPin = ""
        case .failed:
            self.showError("PhotoSafe could not update your PIN. Please try again.")
        }
    }

    private func showError(_ message: String) {
        self.hasError = true
        self.message = message
        self.pinChangeAttempts += 1
    }
}

private struct PinEntryField: View {
    let title: String
    let subtitle: String
    @Binding var text: String
    var trailingText: String?
    let field: ChangePinFocusField
    var focusedField: FocusState<ChangePinFocusField?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(self.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.c1_text)

                    Text(self.subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.c1_text.opacity(0.58))
                }

                Spacer()

                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.c1_primary)
                }
            }

            SecureField("000000", text: self.$text)
                .focused(self.focusedField, equals: self.field)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.c1_background)
                .multilineTextAlignment(.center)
                .padding(.vertical, 11)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.c1_primary)
                )
                .onChange(of: self.text) {
                    self.text = String(self.text.filter(\.isNumber).prefix(6))
                }
        }
    }
}

private enum ChangePinFocusField: Hashable {
    case currentPin
    case newPin
    case confirmPin
}
