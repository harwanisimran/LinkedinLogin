//
//  WebViewController.swift
//  LinkedinLoginDemo
//
//  Created by webwerks on 26/06/19.
//  Copyright © 2019 webwerks. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    // MARK: Constants
    
    let linkedInKey = "81cyte7lnj6x36"
    let linkedInSecret = "9jkV2ISEdsLS9h9K"
    let authorizationEndPoint = "https://www.linkedin.com/uas/oauth2/authorization"
    let accessTokenEndPoint = "https://www.linkedin.com/uas/oauth2/accessToken"
    
    // MARK: ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startAuthorization()
        webView.navigationDelegate = self
        getProfile()
    }
    
    // MARK: Custom Functions
    
    func startAuthorization() {
        // Specify the response type which should always be "code".
        let responseType = "code"
        
        // Set the redirect URL.
        let redirectURL = "https://com.appcoda.linkedin.oauth/oauth"
        
        // Create a random string based on the time intervale (it will be in the form linkedin12345679).
        let state = "linkedin\(Int(NSDate().timeIntervalSince1970))"
        
        // Set preferred scope.
        let scope = "r_liteprofile"
        
        // Create the authorization URL string.
        var authorizationURL = "\(authorizationEndPoint)?"
        authorizationURL += "response_type=\(responseType)&"
        authorizationURL += "client_id=\(linkedInKey)&"
        authorizationURL += "redirect_uri=\(redirectURL)&"
        authorizationURL += "state=\(state)&"
        authorizationURL += "scope=\(scope)"
        
        print(authorizationURL)
        
        // Create a URL request and load it in the web view.
        let request = NSURLRequest(url: NSURL(string: authorizationURL)! as URL)
        webView.load(request as URLRequest)
    }
    
    func requestForAccessToken(authorizationCode: String) {
        
        let grantType = "authorization_code"
        let redirectURL = "https://com.appcoda.linkedin.oauth/oauth"
        
        var postParams = "grant_type=\(grantType)&"
        postParams += "code=\(authorizationCode)&"
        postParams += "redirect_uri=\(redirectURL)&"
        postParams += "client_id=\(linkedInKey)&"
        postParams += "client_secret=\(linkedInSecret)"
        
        // Convert the POST parameters into a NSData object.
        let postData = postParams.data(using: String.Encoding.utf8)
        let request = NSMutableURLRequest(url: NSURL(string: accessTokenEndPoint)! as URL)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task: URLSessionDataTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            
            let statusCode = (response as! HTTPURLResponse).statusCode
            if statusCode == 200 {
                do {
                    let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)as! NSDictionary
                    let accessToken = dataDictionary["access_token"] as! String
                    
                    UserDefaults.standard.set(accessToken, forKey: "LIAccessToken")
                    UserDefaults.standard.synchronize()
                }
                catch {
                    print("Could not convert JSON data into a dictionary.")
                }
            }
        }
        task.resume()
    }
    
    func getProfile() {
        
        if let accessToken = UserDefaults.standard.object(forKey: "LIAccessToken") {
            
            let targetURLString = "https://api.linkedin.com/v2/me"
            let request = NSMutableURLRequest(url: NSURL(string: targetURLString)! as URL)
            request.httpMethod = "GET"
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            let session = URLSession(configuration: URLSessionConfiguration.default)

            let task: URLSessionDataTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
                let statusCode = (response as! HTTPURLResponse).statusCode
                if statusCode == 200 {
                    do {
                        let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)as! NSDictionary
                        print(dataDictionary)
                    }
                    catch {
                        print("Could not convert JSON data into a dictionary.")
                    }
                }
            }
            task.resume()
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            if url.host == "com.appcoda.linkedin.oauth" {
                if url.absoluteString.range(of: "code") != nil {
                    // Extract the authorization code.
                    let urlParts = url.absoluteString.components(separatedBy: "?")
                    let code = urlParts[1].components(separatedBy: "=")[1]
                    
                    requestForAccessToken(authorizationCode: code)
                }
            }
        }
        decisionHandler(.allow)
    }
}
