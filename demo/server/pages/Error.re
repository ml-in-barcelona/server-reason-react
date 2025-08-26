[@react.component]
let make = (~status, ~status_code, ~status_text, ~error: Dream.error) => {
  <html lang="en">
    <head>
      <meta charSet="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <GlobalStyles />
      <title>
        {React.string(Printf.sprintf("%d - %s", status_code, status_text))}
      </title>
      <link href="/output.css" rel="stylesheet" />
    </head>
    <body className="bg-black min-h-screen flex items-center justify-center">
      <div className="max-w-2xl w-full px-6">
        <div className="border-l-4 border-red-400 pl-6">
          <div className="flex items-baseline space-x-4 mb-2">
            <span className="text-5xl font-bold text-red-400 font-mono">
              {React.string(Printf.sprintf("%d", status_code))}
            </span>
          </div>
          <div className="space-y-6">
            <div>
              <h1 className="text-2xl font-bold text-white mb-1 uppercase">
                {React.string(status_text)}
              </h1>
              <p className="text-gray-400 text-lg leading-relaxed">
                {React.string(
                   switch (status_code) {
                   | 400 => "The request contains invalid syntax or cannot be fulfilled."
                   | 401 => "Valid authentication credentials are required to access this resource."
                   | 403 => "You do not have permission to access this resource."
                   | 404 => "The requested resource could not be located on this server."
                   | 405 => "The request method is not supported for this resource."
                   | 408 => "The server timed out waiting for the request."
                   | 429 => "Too many requests. Please try again later."
                   | 500 => "The server encountered an unexpected condition that prevented it from fulfilling the request."
                   | 502 => "The server received an invalid response from the upstream server."
                   | 503 => "The server is currently unable to handle the request. Please try again later."
                   | _ => "An unexpected error occurred while processing your request."
                   },
                 )}
              </p>
            </div>
            <div className="pt-6 border-t border-gray-800">
              <div className="flex items-center justify-between">
                <div
                  className="text-sm text-gray-500 font-mono gap-2 inline-flex items-center">
                  {React.string("Error Code: ")}
                  <p className="font-bold">
                    {React.string(
                       Printf.sprintf("%s", Dream.status_to_string(status)),
                     )}
                  </p>
                </div>
                <div className="text-sm text-gray-500">
                  {React.string(
                     switch (error.client) {
                     | Some(client) => "Client: " ++ client
                     | None => "Timestamp: " ++ Float.to_string(Unix.time())
                     },
                   )}
                </div>
              </div>
            </div>
            <div className="flex space-x-4 pt-4">
              <a
                href="/"
                className="px-6 py-3 bg-white text-black font-semibold hover:bg-gray-200 transition-colors">
                {React.string("Return Home")}
              </a>
            </div>
          </div>
        </div>
      </div>
    </body>
  </html>;
};
