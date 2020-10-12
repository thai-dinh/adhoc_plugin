// import android.annotation.SuppressLint;
// import android.os.Looper;
// import android.os.Message;
// import android.util.Log;

// public class Service {
//     protected final String TAG = "[AdHoc][Service]";

//     protected final boolean verbose;

//     // Constant for type
//     static final int WIFI = 0;
//     static final int BLUETOOTH = 1;

//     // Constants that indicate the current connection state
//     static final int STATE_NONE = 0;            // no connection
//     static final int STATE_LISTENING = 1;       // listening for incoming connections
//     static final int STATE_CONNECTING = 2;      // initiating an outgoing connection
//     static final int STATE_CONNECTED = 3;       // connected to a remote device

//     // Constants for message handling
//     static final int MESSAGE_READ = 5;          // message received

//     // Constants for connection
//     static final int CONNECTION_ABORTED = 6;    // connection aborted
//     static final int CONNECTION_PERFORMED = 7;  // connection performed
//     static final int CONNECTION_FAILED = 8;     // connection failed

//     static final int LOG_EXCEPTION = 9;         // log exception
//     static final int MESSAGE_EXCEPTION = 10;    // catch message exception
//     static final int NETWORK_UNREACHABLE = 11;

//     Service(boolean verbose) {
//         this.verbose = verbose;
//     }

//     @SuppressLint("HandlerLeak")
//     protected final android.os.Handler handler = new android.os.Handler(Looper.getMainLooper()) {
//         @Override
//         public void handleMessage(Message msg) {
//             switch (msg.what) {
//                 case MESSAGE_READ:
//                     if (verbose) Log.d(TAG, "MESSAGE_READ");
//                     serviceMessageListener.onMessageReceived((MessageAdHoc) msg.obj);
//                     break;
//                 case CONNECTION_ABORTED:
//                     if (verbose) Log.d(TAG, "CONNECTION_ABORTED");
//                     serviceMessageListener.onConnectionClosed((String) msg.obj);
//                     break;
//                 case CONNECTION_PERFORMED:
//                     if (verbose) Log.d(TAG, "CONNECTION_PERFORMED");
//                     serviceMessageListener.onConnection((String) msg.obj);
//                     break;
//                 case CONNECTION_FAILED:
//                     if (verbose) Log.d(TAG, "CONNECTION_FAILED");
//                     serviceMessageListener.onConnectionFailed((Exception) msg.obj);
//                     break;
//                 case MESSAGE_EXCEPTION:
//                     if (verbose) Log.e(TAG, "MESSAGE_EXCEPTION");
//                     serviceMessageListener.onMsgException((Exception) msg.obj);
//                     break;
//                 case LOG_EXCEPTION:
//                     if (verbose) Log.w(TAG, "LOG_EXCEPTION: " + ((Exception) msg.obj).getMessage());
//                     break;
//                 default:
//                     break;
//             }
//         }
//     };
// }
