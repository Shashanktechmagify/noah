import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The phone's own share sheet, for sharing a link to a Noahgram post.
    let channel = FlutterMethodChannel(name: "noah/share", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "text", let text = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
      let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
      let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
      sheet.popoverPresentationController?.sourceView = root?.view
      root?.present(sheet, animated: true)
      result(nil)
    }
  }
}
