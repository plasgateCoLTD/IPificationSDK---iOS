import SwiftUI
import PlasgateAuthSDK

// MARK: - Content View
struct ContentView: View {
    // MARK: - Properties
    
    /// View model for authentication
    @StateObject private var viewModel = AuthenticationViewModel()
    
    // MARK: - UI
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Input Section
                    inputSection
                    
                    // Action Button
                    actionButton
                    
                    // Result Display
                    if let result = viewModel.authResult {
                        resultSection(result)
                    }
                    
                    // SDK Info
                    sdkInfoSection
                }
                .padding()
            }
            .alert("Authentication Result", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.statusMessage)
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Header section with title and description
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding()
            
            Text("Plasgate IPification Demo")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Authenticate users seamlessly using their phone number")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    /// Input section for phone number
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phone Number")
                .font(.headline)
            
            TextField("Enter phone number (e.g. 85516772627)", text: $viewModel.phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .padding(.bottom, 8)
                .disabled(viewModel.isAuthenticating)
            
            Text("Enter the phone number including country code")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    /// Action button for authentication
    private var actionButton: some View {
        Button(action: viewModel.authenticate) {
            HStack {
                Text("Authenticate")
                if viewModel.isAuthenticating {
                    Spacer()
                    ProgressView()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(viewModel.isAuthenticating || viewModel.phoneNumber.isEmpty)
    }
    
    /// Result section showing authentication result
    private func resultSection(_ result: AuthenticationResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Authentication Result")
                .font(.headline)
                .padding(.top)
            
            ResultRow(title: "User ID", value: result.sub)
            ResultRow(title: "Phone", value: result.login_hint)
            ResultRow(title: "Verified", value: result.phone_number_verified ? "Yes" : "No")
            ResultRow(title: "Mobile ID", value: result.mobile_id)
            
            if let status = result.status {
                ResultRow(title: "Status", value: status)
            }
            
            if let sid = result.sid {
                ResultRow(title: "Session ID", value: sid)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    /// SDK info section
    private var sdkInfoSection: some View {
        VStack {
            Divider()
                .padding(.vertical)
            
            Text("PlasgateAuthSDK v\(PlasgateAuthSDK.version)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
}

// MARK: - Helper Views

/// A row that displays a title and value
struct ResultRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
