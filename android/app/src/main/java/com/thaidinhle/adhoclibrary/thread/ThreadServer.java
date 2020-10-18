package com.thaidinhle.adhoclibrary;

import android.util.Log;

public class ThreadServer extends Thread {
    private static final String TAG = "[AdHoc][Thread.Server]";

    private final String suffix;

    public ThreadServer(String suffix) {
        this.suffix = suffix;
    }

    public void run() {
        int i = 0;
        while (true) {
            i++;

            if (i % 50000 == 0)
                Log.d(TAG, "Hello" + suffix);
        } 
    }
} 
