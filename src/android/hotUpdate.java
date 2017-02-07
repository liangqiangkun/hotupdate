package com.mLink.cordova.plugin.hotUpdate;
import android.content.Context;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import java.lang.reflect.Method;

public class hotUpdate extends CordovaPlugin {
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        System.out.println("hahhahahhah ");
        return super.execute(action, args, callbackContext);
    }
    public void downLoadAndUpdateHTMLResouce(String url,CallbackContext callbackContext){
        
    }
}