// ZeroFrame code taken directly from ZeroNet sample sites
var ZF = new ZeroFrame();

// Elm tie-in
var app = Elm.Main.fullscreen();

// wrapperConfirm
app.ports.wrapperConfirm_.subscribe(function(params) {
	ZF.cmd("wrapperConfirm",params,function(confirmed) {
		app.ports.onWrapperConfirm_.send(confirmed);
	})
});

// wrapperInnerLoaded
app.ports.wrapperInnerLoaded.subscribe(function() {
	ZF.cmd("wrapperInnerLoaded",[]);
});

// wrapperGetLocalStorage
app.ports.wrapperGetLocalStorage.subscribe(function() {
	ZF.cmd("wrapperGetLocalStorage",[],function(res) {
		app.ports.onLocalStorage_.send(res);
	});
});

// wrapperGetState
app.ports.wrapperGetState.subscribe(function() {
	ZF.cmd("wrapperGetState",[],function(res) {
		app.ports.onGetState_.send(res);
	});
});

// wrapperNotification
app.ports.wrapperNotification_.subscribe(function(params) {
	ZF.cmd("wrapperNotification",params);
});

// wrapperOpenWindow
app.ports.wrapperOpenWindow_.subscribe(function(params) {
	ZF.cmd("wrapperOpenWindow",params);
});

// wrapperPermissionAdd
app.ports.wrapperPermissionAdd.subscribe(function(permission) {
	ZF.cmd("wrapperPermissionAdd",[permission]);
});

// wrapperPrompt
app.ports.wrapperPrompt_.subscribe(function(params) {
	ZF.cmd("wrapperPrompt",params,function(res) {
		app.ports.onPrompt_.send(res);
	});
});

// wrapperPushState
app.ports.wrapperPushState_.subscribe(function(params) {
	ZF.cmd("wrapperPushState",params);
});

// wrapperReplaceState
app.ports.wrapperReplaceState_.subscribe(function(params) {
	ZF.cmd("wrapperReplaceState",params);
});

// wrapperSetLocalStorage
app.ports.wrapperSetLocalStorage.subscribe(function(data) {
	ZF.cmd("wrapperSetLocalStorage",data);
});

// wrapperSetTitle
app.ports.wrapperSetTitle.subscribe(function(title) {
	ZF.cmd("wrapperSetTitle",title);
});

// wrapperSetViewport
app.ports.wrapperSetViewport.subscribe(function(viewport) {
	ZF.cmd("wrapperSetViewport",viewport);
});

// certAdd
app.ports.certAdd_.subscribe(function(params) {
	ZF.cmd("certAdd",params,function(res) {
		app.ports.onCertAdd_.send(res);
	});
});

// certSelect
app.ports.certSelect.subscribe(function(ad) {
	ZF.cmd("certSelect",{"accepted_domains": ad});
});

// channelJoin
app.ports.channelJoin.subscribe(function(c) {
	ZF.cmd("channelJoin",{"channel": c});
});

// dbQuery
app.ports.dbQuery.subscribe(function(q) {
	ZF.cmd("dbQuery",[q],function(res) {
		app.ports.onQueryResult_.send(res);
	});
});

// fileDelete
app.ports.fileDelete.subscribe(function(path) {
	ZF.cmd("fileDelete",path,function(res) {
		app.ports.onFileDelete_.send(res);
	});
});

// fileGet
app.ports.fileGet_.subscribe(function(params) {
	ZF.cmd("fileGet",params,function(res) {
		app.ports.onFileGet_.send(res);
	});
});

// fileList
app.ports.fileList.subscribe(function(path) {
	ZF.cmd("fileList",path,function(res) {
		app.ports.onFileList_.send(res);
	});
});

// fileQuery
app.ports.fileQuery_.subscribe(function(params) {
	ZF.cmd("fileQuery",params,function(res) {
		app.ports.onFileQuery_.send(res);
	});
});

// fileRules
app.ports.fileRules.subscribe(function(path) {
	ZF.cmd("fileRules",path,function(res) {
		app.port.onFileRules_.send(res);
	});
});

// fileWrite
app.ports.fileWrite_.subscribe(function(params) {
	ZF.cmd("fileWrite",params,function(res) {
		app.ports.onFileWrite_.send(res);
	});
});

// serverInfo
app.ports.serverInfo.subscribe(function() {
	ZF.cmd("serverInfo", {}, function(res) {
		app.ports.onServerInfo_.send(res);
	});
});

// siteInfo
app.ports.siteInfo.subscribe(function() {
	ZF.cmd("siteInfo", {}, function(res) {
		app.ports.onSiteInfo_.send(res);
	});
});

// sitePublish
app.ports.sitePublish_.subscribe(function(params) {
	ZF.cmd("sitePublish",params,function(res) {
		app.ports.onSitePublish_.send(res);
	});
});

// siteSign
app.ports.siteSign_.subscribe(function(params) {
	ZF.cmd("siteSign",params,function(res) {
		app.ports.onSiteSign_.send(res);
	});
});

// mergerSiteAdd
app.ports.mergerSiteAdd.subscribe(function(addresses) {
	ZF.cmd("mergerSiteAdd",addresses);
});

// mergerSiteDelete
app.ports.mergerSiteDelete.subscribe(function(a) {
	ZF.cmd("mergerSiteDelete",a)
});

// mergerSiteList
app.ports.mergerSiteList.subscribe(function(q) {
	ZF.cmd("mergerSiteList",q,function(res) {
		app.ports.onMergerSiteList_.send(res);
	});
});
