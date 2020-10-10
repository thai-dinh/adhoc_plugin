import android.annotation.SuppressLint;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

public class Service {
    protected final String TAG = "[AdHoc][Service]";

    protected final boolean verbose;

    Service(boolean verbose) {
        this.verbose = verbose;
    }

    @SuppressLint("HandlerLeak")
    protected final android.os.Handler handler = new android.os.Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MESSAGE_READ:
                    if (verbose) Log.d(TAG, "MESSAGE_READ");
                    serviceMessageListener.onMessageReceived((MessageAdHoc) msg.obj);
                    break;
                case CONNECTION_ABORTED:
                    if (verbose) Log.d(TAG, "CONNECTION_ABORTED");
                    serviceMessageListener.onConnectionClosed((String) msg.obj);
                    break;
                case CONNECTION_PERFORMED:
                    if (verbose) Log.d(TAG, "CONNECTION_PERFORMED");
                    serviceMessageListener.onConnection((String) msg.obj);
                    break;
                case CONNECTION_FAILED:
                    if (verbose) Log.d(TAG, "CONNECTION_FAILED");
                    serviceMessageListener.onConnectionFailed((Exception) msg.obj);
                    break;
                case MESSAGE_EXCEPTION:
                    if (verbose) Log.e(TAG, "MESSAGE_EXCEPTION");
                    serviceMessageListener.onMsgException((Exception) msg.obj);
                    break;
                case LOG_EXCEPTION:
                    if (verbose) Log.w(TAG, "LOG_EXCEPTION: " + ((Exception) msg.obj).getMessage());
                    break;
                default:
                    break;
            }
        }
    };
}
