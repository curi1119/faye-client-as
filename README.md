# Faye Client for ActionScript3


What's this
-----------
This is an AS3 implementation of the [Faye](https://github.com/faye/faye) Client library.

This is NOT Faye team's *official* project. Do NOT ask about this to Faye team.

Faye supports Ruby and Javascript. Flash(AS) cannot communicate with faye server directly.
This library adds ability to the Flash work with faye server by using the WebSocket.

*Note: Only Faye::Client part was translated to AS.*


Usage Example
-------------

    var faye:FayeClient;
    faye = Faye.Client('http://localhost:6500/faye', {timeout: 120});
    faye.subscribe('/test', false, function(message:Object):void {
       trace("recived:", JSON.stringify(messages));
    });
    faye.publish('/test', {message: 'hello world'});


About Flash Security Policy file
-------------
faye-client-as uses HTTP on handshake, and then switch to WebSocket. This means, SWF using faye-client-as requires crosscomain.xml and socket policy file from your server.

I wrote example that faye(using thin) server returns /crosscomain.xml.[example](https://github.com/curi1119/faye-client-as/blob/master/faye/faye.ru)
For socket policy file, you should visit [AdobeSite](http://www.adobe.com/devnet/flashplayer/articles/socket_policy_files.html), and download flashpolicyd.

More detail about Flash Policy file
- [Policy file changes in Flash Player 9 and Flash Player 10](http://www.adobe.com/devnet/flashplayer/articles/fplayer9_security.html)
- [Setting up a socket policy file server](http://www.adobe.com/devnet/flashplayer/articles/socket_policy_files.html)


Included swc
-------------
Following libs are included:
- [AS3WebSocket](https://github.com/Worlize/AS3WebSocket)
- [promise-as3](https://github.com/CodeCatalyst/promise-as3)
