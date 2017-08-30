// Grab the nonce
w_nonce = document.location.href.replace(/.*wrapper_nonce=([A-Za-z0-9]+).*/, "$1"); 

// sendZeroFrameMsg
app.ports.sendZeroFrameMsg.subscribe(function(message) {
	message.wrapper_nonce = w_nonce;
	window.parent.postMessage(message, "*");
})

// recvZeroFrameMsg 
window.addEventListener("message", function(e) {
	app.ports.recvZeroFrameMsg.send(e.data);
}, false);
