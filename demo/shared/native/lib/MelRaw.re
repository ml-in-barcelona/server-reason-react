let%browser_only initWebsocket = () => [%mel.raw
  {|
    function initWebsocket() {
      var socketUrl = "ws://" + location.host + "/_livereload";
      var s = new WebSocket(socketUrl);

      s.onopen = function(even) {
        console.debug("Live reload: WebSocket connection open");
      };

      s.onclose = function(even) {
        console.debug("Live reload: WebSocket connection closed");

        var retryIntervalMs = 500;

        function reload() {
          s2 = new WebSocket(socketUrl);

          s2.onerror = function(event) {
            setTimeout(reload, retryIntervalMs);
          };

          s2.onopen = function(event) {
            location.reload();
          };
        };

        reload();
      };

      s.onerror = function(event) {
        console.debug("Live reload: WebSocket error:", event);
      };
    }
|}
];

let x = 22;
