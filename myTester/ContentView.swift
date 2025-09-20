//
//  ContentView.swift
//  myTester
//
//  Created by Rajesh Solanki on 9/19/25.
//

import SwiftUI
import MessageUI

// MARK: - App Detection Utility
class AppDetectionUtility {
    static let shared = AppDetectionUtility()
    
    private init() {}
    
    func isAppInstalled(urlScheme: String) -> Bool {
        guard let url = URL(string: "\(urlScheme)://") else {
            print("❌ Invalid URL scheme: \(urlScheme)")
            return false
        }
        
        // Use a more permissive approach
        if Thread.isMainThread {
            let canOpen = UIApplication.shared.canOpenURL(url)
            print("🔍 Checking \(urlScheme):// - Result: \(canOpen)")
            return canOpen
        } else {
            var canOpen = false
            DispatchQueue.main.sync {
                canOpen = UIApplication.shared.canOpenURL(url)
                print("🔍 Checking \(urlScheme):// - Result: \(canOpen)")
            }
            return canOpen
        }
    }
    
    func detectInstalledApps() -> [String: Bool] {
        let schemes = [
            "whatsapp": ["whatsapp://", "whatsapp://send", "whatsapp://call"],
            "telegram": ["tg://", "tg://resolve", "telegram://"],
            "facetime": ["facetime://", "facetime-audio://"],
            "signal": ["sgnl://", "sgnl://send", "signal://"],
            "viber": ["viber://", "viber://chat", "viber://call"]
        ]
        
        var results: [String: Bool] = [:]
        
        for (app, urlSchemes) in schemes {
            let isInstalled = urlSchemes.contains { scheme in
                isAppInstalled(urlScheme: scheme)
            }
            results[app] = isInstalled
            print("📱 \(app.capitalized): \(isInstalled ? "✅ Installed" : "❌ Not installed")")
        }
        
        return results
    }
}

// MARK: - Data Models
struct Contact: Codable, Identifiable {
    let id = UUID()
    var name: String
    var phoneNumber1: String
    var phoneNumber2: String
    var dialMethod1: DialMethod
    var dialType1: DialType
    var dialMethod2: DialMethod
    var dialType2: DialType
}

enum DialMethod: String, CaseIterable, Codable {
    case phone = "Phone"
    case whatsapp = "WhatsApp"
    case telegram = "Telegram"
    case facetime = "FaceTime"
    case signal = "Signal"
    case viber = "Viber"
    
    var isAvailable: Bool {
        let result: Bool
        switch self {
        case .phone:
            result = true // Always available
        case .whatsapp:
            result = AppDetectionUtility.shared.isAppInstalled(urlScheme: "whatsapp")
        case .telegram:
            result = AppDetectionUtility.shared.isAppInstalled(urlScheme: "tg")
        case .facetime:
            result = true // FaceTime should always be available on iOS
        case .signal:
            result = AppDetectionUtility.shared.isAppInstalled(urlScheme: "sgnl")
        case .viber:
            result = AppDetectionUtility.shared.isAppInstalled(urlScheme: "viber")
        }
        print("\(self.rawValue) is available: \(result)")
        return result
    }
}

enum DialType: String, CaseIterable, Codable {
    case voice = "Voice"
    case video = "Video"
    case text = "Text"
}

// MARK: - Contact View
struct ContactView: View {
    @Binding var contact: Contact
    let contactNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Contact Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("Contact \(contactNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Name Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Name:")
                    .font(.headline)
                TextField("Enter name", text: $contact.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Phone Number 1 Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number 1:")
                    .font(.headline)
                
                TextField("Enter phone number", text: $contact.phoneNumber1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
                
                VStack(spacing: 12) {
                    // Dial Method Dropdown
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dial Method:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("Dial Method", selection: $contact.dialMethod1) {
                            ForEach(availableDialMethods, id: \.self) { method in
                                Text(method.rawValue).tag(method)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Dial Type Dropdown
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dial Type:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("Dial Type", selection: $contact.dialType1) {
                            ForEach(DialType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Dial Out Button 1
                Button(action: {
                    hideKeyboard()
                    dialOut(phoneNumber: contact.phoneNumber1, method: contact.dialMethod1, type: contact.dialType1)
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Dial Out")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(contact.phoneNumber1.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(contact.phoneNumber1.isEmpty)
            }
            
            // Phone Number 2 Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number 2:")
                    .font(.headline)
                
                TextField("Enter phone number", text: $contact.phoneNumber2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
                
                VStack(spacing: 12) {
                    // Dial Method Dropdown
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dial Method:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("Dial Method", selection: $contact.dialMethod2) {
                            ForEach(availableDialMethods, id: \.self) { method in
                                Text(method.rawValue).tag(method)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Dial Type Dropdown
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dial Type:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("Dial Type", selection: $contact.dialType2) {
                            ForEach(DialType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Dial Out Button 2
                Button(action: {
                    hideKeyboard()
                    dialOut(phoneNumber: contact.phoneNumber2, method: contact.dialMethod2, type: contact.dialType2)
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Dial Out")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(contact.phoneNumber2.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(contact.phoneNumber2.isEmpty)
            }
            
            // Debug section - show detected apps
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("App Detection Debug:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        // Force refresh by triggering app detection
                        _ = AppDetectionUtility.shared.detectInstalledApps()
                    }
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                }
                
                ForEach(DialMethod.allCases, id: \.self) { method in
                    HStack {
                        Image(systemName: method.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(method.isAvailable ? .green : .red)
                        Text(method.rawValue)
                            .font(.caption)
                        Spacer()
                        Text(method.isAvailable ? "✓" : "✗")
                            .font(.caption)
                            .foregroundColor(method.isAvailable ? .green : .red)
                    }
                }
                
                Text("Note: Apps must be installed on device/simulator")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
                
                Text("If apps don't show, try running on a real device")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
            
            Spacer(minLength: 20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var availableDialMethods: [DialMethod] {
        let available = DialMethod.allCases.filter { $0.isAvailable }
        print("Available dial methods: \(available.map { $0.rawValue })")
        
        // Debug: Print all methods and their availability
        for method in DialMethod.allCases {
            print("\(method.rawValue): \(method.isAvailable)")
        }
        
        return available
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func dialOut(phoneNumber: String, method: DialMethod, type: DialType) {
        guard !phoneNumber.isEmpty else { return }
        
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        var urlString: String
        
        switch method {
        case .phone:
            urlString = "tel:\(cleanNumber)"
        case .whatsapp:
            switch type {
            case .voice:
                urlString = "whatsapp://call?phone=\(cleanNumber)"
            case .video:
                urlString = "whatsapp://video?phone=\(cleanNumber)"
            case .text:
                urlString = "whatsapp://send?phone=\(cleanNumber)"
            }
        case .telegram:
            urlString = "tg://resolve?domain=\(cleanNumber)"
        case .facetime:
            switch type {
            case .voice:
                urlString = "facetime:\(cleanNumber)"
            case .video:
                urlString = "facetime:\(cleanNumber)"
            case .text:
                urlString = "sms:\(cleanNumber)"
            }
        case .signal:
            urlString = "sgnl://send?phone=\(cleanNumber)"
        case .viber:
            urlString = "viber://chat?number=\(cleanNumber)"
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var contact1 = Contact(
        name: "",
        phoneNumber1: "",
        phoneNumber2: "",
        dialMethod1: .phone,
        dialType1: .voice,
        dialMethod2: .phone,
        dialType2: .voice
    )
    
    @State private var contact2 = Contact(
        name: "",
        phoneNumber1: "",
        phoneNumber2: "",
        dialMethod1: .phone,
        dialType1: .voice,
        dialMethod2: .phone,
        dialType2: .voice
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                HStack(spacing: 0) {
                    // Contact 1 - Left Half
                    ContactView(contact: $contact1, contactNumber: 1)
                        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.8)
                    
                    Divider()
                        .background(Color.gray)
                    
                    // Contact 2 - Right Half
                    ContactView(contact: $contact2, contactNumber: 2)
                        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.8)
                }
            }
            .navigationTitle("Contact Dialer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        hideKeyboard()
                        saveContacts()
                    }
                }
            }
        }
        .onAppear {
            loadContacts()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveContacts() {
        let contacts = [contact1, contact2]
        if let encoded = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(encoded, forKey: "SavedContacts")
        }
    }
    
    private func loadContacts() {
        if let data = UserDefaults.standard.data(forKey: "SavedContacts"),
           let contacts = try? JSONDecoder().decode([Contact].self, from: data),
           contacts.count >= 2 {
            contact1 = contacts[0]
            contact2 = contacts[1]
        }
    }
}

#Preview {
    ContentView()
}
