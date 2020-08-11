1. Drag the following bundles into your project [Frameworks] (select Copy items if needed)
    1. [Emtgar.framework]
    2. [EmtgarResources.bundle]
    3. [KudanAR.framework]
2. Open the Build Phases tab for your application’s target, and within Link Binary with Libraries, add the following frameworks:
    1. libc++.tbd
3. Open the Build Setting search Enable Bitcode Edit Enable Bitcode to NO
4. Add Google Frameworks following link https://developers.google.com/maps/documentation/ios-sdk/start#install-manually
5. Drag ConfigLib.plist into your project (select Copy items if needed)
Edit value if you need
6. Open info.plist Add
    - Privacy - Photo Library Usage Description
    - Privacy - Location When In Use Usage Description
    - Privacy - Camera Usage Description
    - Add URL Type
    - If use http add App Transport Security Settings set Allow Arbitrary Loads = YES
7. Open Appdelegate.swift add or update a few methods
```
    import KudanAR
    import GoogleMaps
    import emtgar
    @UIApplicationMai
    class AppDelegate: UIResponder, UIApplicationDelegate {
            var window: UIWindow?
           func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                    GMSServices.provideAPIKey(“your google apikey”)
                    return true
            }

            func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
                    return ARSDKApplicationDelegate.sharedInstance().openSchemeUrl((self.window?.rootViewController)!, open: url)
            }

    }
```
8. Open SceneDelegate.swift add or update a few methods
```
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
                if let url = URLContexts.first?.url {
                    ARSDKApplicationDelegate.sharedInstance().scene((self.window?.rootViewController)!, openURL: url)
                }
        }
```
9. Create WebView  
```
    import UIKit
    import WebKit
    import emtgar

    private let webUrl = "https://dev-kobukuro.emtg.xyz/feature/0ce91031954b8e9a8dce895a1e295f56"

    class YourClassName: UIViewController{

           var webView: WKWebView!

            override func loadView() {
                    let webConfiguration = WKWebViewConfiguration()
                    webView = WKWebView(frame: .zero, configuration: webConfiguration)
                    webView.uiDelegate = self
                    webView.navigationDelegate = self
                    view = webView
            }

            override func viewDidLoad() {
                    super.viewDidLoad()

                    let url = URL(string: webUrl)
                    let myRequest = URLRequest(url: url!)
                    webView.load(myRequest)
            }
    }

    extension YourClassName: WKUIDelegate, WKNavigationDelegate {
            func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
                    let user = "ajtja"
                    let password = "dmwmd"
                    let credential = URLCredential(user: user, password: password, persistence: URLCredential.Persistence.forSession)
                    challenge.sender?.use(credential, for: challenge)
                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)

    }
    
            func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

                    if let url = navigationAction.request.url, !url.absoluteString.hasPrefix("http://"), !url.absoluteString.hasPrefix("https://") {
                    //let newUrl = url.absoluteString + "?uid=" + ApplicationModel.shared.AID + "&aid=" + ApplicationModel.shared.AID
                   let newUrl = url.absoluteString + "?uid=" + "21d62d1e0a404e3060511fb5f12d6359" + "&aid=" + "9a419a1867e5ab85abe068d09004c564"
                    UIApplication.shared.open(URL(string: newUrl)!, options: [:], completionHandler: nil)

                    decisionHandler(.cancel)
                }
                else {
                    // allow the request
                    decisionHandler(.allow)
        }
    }
}

```
