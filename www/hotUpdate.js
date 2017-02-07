var exec = require('cordova/exec'), cordova = require('cordova');
var hotUpdate = function () {
};
//下载服务器上的web资源
hotUpdate.prototype.downLoadAndUpdateHTMLResouce = function(args,suceess,error){
  exec(suceess,error,"hotUpdate","downLoadAndUpdateHTMLResouce",[args]);
};

module.exports = new hotUpdate();
