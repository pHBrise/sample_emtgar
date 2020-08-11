//
//  ViewController.swift
//  EMTGAR-Sample
//
//  Created by Mac mini ssd500 on 11/8/20.
//  Copyright © 2020 PROUDIA. All rights reserved.
//

import UIKit
import WebKit
import emtgar

private let webUrl = "https://dev-kobukuro.emtg.xyz/feature/0ce91031954b8e9a8dce895a1e295f56"

class ViewController: UIViewController{

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

extension ViewController: WKUIDelegate, WKNavigationDelegate {
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
