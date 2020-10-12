import android.content.Context;
import android.net.wifi.WifiManager;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class WifiAdHocManager implements MethodCallHandler {
    private static final String TAG = "[AdHoc][WifiManager]";

    private Context context;

    WifiAdHocManager(Context context) {
        this.context = context;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "enable":
                wifiAdapterState(true);
                break;
            case "disable":
                disable();
                break;
            default:
                break;
        }
    }

    private void wifiAdapterState(boolean state) {
        WifiManager wifi = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        if (wifi != null) {
            wifi.setWifiEnabled(state);
        }
    }

    private void disable() {
        wifiAdapterState(false);
    }
}
