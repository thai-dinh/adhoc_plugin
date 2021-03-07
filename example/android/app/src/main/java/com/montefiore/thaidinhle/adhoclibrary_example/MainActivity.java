package com.montefiore.thaidinhle.adhoclibrary_example;

import android.media.AudioAttributes;
import android.media.MediaPlayer;
import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.io.IOException;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "adhoc.music.player/main";
    private MediaPlayer mediaPlayer;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    switch (call.method) {
                        case "play":
                            final String path = call.arguments();
                            play(path);
                            break;

                        default:
                            break;
                    }
                }
            );
    }

    private void play(String path) {
        if (mediaPlayer == null) {
            mediaPlayer = new MediaPlayer();

            try {
                mediaPlayer.setDataSource(path);
            } catch (IOException e) {

            }

            mediaPlayer.setAudioAttributes(new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            );

            try {
                mediaPlayer.prepare();
            } catch (IOException e) {

            }
        }

        mediaPlayer.start();
    }
}
