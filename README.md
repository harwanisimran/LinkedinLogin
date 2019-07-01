# Linkedin Integration in iOS Application 

## LinkedIn-Login

To integrate LinkedIn with your mobile application, we need to create an new application in LinkedIn Developer’s Account. Go to https://www.linkedin.com/developer/apps and click on the Create Application button and a form will open that need to be filled to successfully create application on LinkedIn.
After creating application on LinkedIn, in the mobile app settings tab you will find the Client ID and Client Secret values. We are in need of that values latter.

Issue: Issue of redirect Url
One important task we have to do here (besides than simply having access to the client keys), is to add a value to the Authorized Redirect URLs field. An authorized redirect URL is mostly needed when the client app tries to refresh an existing access token, and the user isn’t required to explicitly sign in again through a web browser. The OAuth flow will automatically redirect the app using that URL. 
The redirection URL does’t have to be a real, existing URL. It can be any value you wish starting with the “https://” prefix.

## Set the Permission

We need to set the permission to get the access to retrieve the user’s LinkedIn profile details. We need to select the r_basicprofile and r_emailaddress and click on the update button to set the permission.

## Initiating the Authorization Process

In the Xcode select the WebViewController.swift file in the Project Navigator to open it. At the top of the class, add two variables named linkedInKey and authorizationEndPoint. You have to assign the Client ID to linkedInKey variable by getting them from the LinkedIn Developers website. And assign “https://www.linkedin.com/uas/oauth2/authorization” URL to autorizationEndPoint property which must be used for the request
Our main goal in this step is to prepare the request for getting the authorization code, and to load it through a web view. The WebViewController scene in the Interface Builder already contains a web view, therefore we’re going to work on the WebViewController class. The request for getting the authorization code must contain mandatorily the following parameters:
* response_type: It’s a standard value that must always be: code.
* client_id: It’s the Client ID value taken from the LinkedIn Developers website and been assigned to the linkedInKey property of our project.
* redirect_uri: The authorized redirection URL value that you specified in the previous part. Make sure to copy and paste it properly in the following code snippets.
* state: A unique string required to prevent a cross-site request forgery (CSRF).
* scope: A URL-encoded list of the permissions that our app requests.
 
Speaking in terms of code now, let’s create a new function in the WebViewController class where we’ll prepare our request. We’ll name it startAuthorization(). The first task in it is to specify the most of the request parameters described right before, exactly as shown in the following snippet:
 ```
     func startAuthorization() {
     
         // Specify the response type which should always be "code".
         let responseType = "code"
 
         // Set the redirect URL. 
         let redirectURL = "https://com.appcoda.linkedin.oauth/oauth".
  
         // Create a random string based on the time interval (it will be in the form linkedin12345679).
         let state = "linkedin\(Int(NSDate().timeIntervalSince1970))"
 
         // Set preferred scope.
         let scope = "r_basicprofile"
         
    }  
 ```   

The scope gets the “r_basicprofile” value, matching to the permission that I set to the app in the LinkedIn Developers website. When you set permissions, make sure to take a look at this text from the official documentation.

Our next step is to compose the authorization URL. Note that the https://www.linkedin.com/uas/oauth2/authorization URL must be used for the request, which is already assigned to the authorizationEndPoint property.

Back in our code again:
```
    func startAuthorization() {
      ...

      // Create the authorization URL string.
      var authorizationURL = "\(authorizationEndPoint)?"
      authorizationURL += "response_type=\(responseType)&"
      authorizationURL += "client_id=\(linkedInKey)&"
      authorizationURL += "redirect_uri=\(redirectURL)&"
      authorizationURL += "state=\(state)&"
      authorizationURL += "scope=\(scope)"
 
      print(authorizationURL)
    }
 ```

I added the print line above just to let you see with your own eyes in the console how the request is finally formed.
Finally, the last action we have to do here is to load the request in our web view. Keep in mind that user will be able to sign in through the web view if only the above request is properly formed. In any other case, LinkedIn will return error messages and you won’t be able to proceed any further. Therefore, make sure that you copy the Client Key and Secret values properly, as well as the authorized redirect URL.
Loading the request in the web view takes just a couple of lines:
 ```
    func startAuthorization() {
      ...
 
      // Create a URL request and load it in the web view.
      let request = NSURLRequest(URL: NSURL(string: authorizationURL)!)
      webView.loadRequest(request)
    }
 ```

Before we get to the end of this part, we have to call the above function. This is going to take place in the viewDidLoad(_: ) function:
 ```
    override func viewDidLoad() {
       ...
 
       startAuthorization()
    }
 ```    

Don’t sign in to your LinkedIn account yet, as there are still things remaining to be done on our part.

## Getting an Authorization Code

By having the authorization code request ready and loaded in the web view, we can proceed by implementing the webView(:shouldStartLoadWithRequest:navigationType) delegate method. In this one we’ll “catch” the LinkedIn response, and we’ll extract the desired authentication code from it.

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

Besides the two new lines above, you can also notice a call to another function named requestForAccessToken(_: ). This is a new custom function that we’re about to implement in the next part. In it, we’ll ask for the access token using the authorization code taken in this step.

Requesting for the Access Token

All the communication we’ve had so far with the LinkedIn server was through the web view. From now on, we’re going to “talk” to the server only through easy RESTful requests (simple POST and GET requests). More precisely, we’re going to make one POST request for getting the access token, and one GET request for asking for the user profile URL later.

Having said that, it’s time to move and create the new custom function that I mentioned about in the last part, the requestForAccessToken().

## Preparing the POST parameters

Similarly to the request preparation for getting the authorization code, we need to post specific parameters and their values along with the request for the access token too. These parameters are:
* grant_type: It’s a standard value that should always be: authorization_code.
* code: The authorization code acquired in the previous part.
* redirect_uri: It’s the authorized redirection URL we’ve talked about many times earlier.
* client_id: The Client Key value.
* client_secret: The Client Secret Value. 

The authorization code that we fetched in the previous part is going to be given as a parameter in our new function. 

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

Let’s focus now on the getProfileInfo() method. This one is called when the Get my profile URL button is tapped.

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

By running the app now, and considering that you’ve acquired an access token successfully, you’ll see the response containing users detail.



