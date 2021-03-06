package com.montefiore.thaidinhle.adhoclibrary_example;

import android.database.Cursor;
import android.media.AudioAttributes;
import android.media.AudioAttributes.Builder;
import android.media.MediaPlayer;
import android.provider.MediaStore;
import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;


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
                        case "fetch":
                            result.success(fetchSongsInfo());
                            break;
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

    private List<String> fetchSongsInfo() {
        String[] projection = {
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DURATION
        };

        Cursor music = getContentResolver().query(
            android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            MediaStore.Audio.Media.IS_MUSIC + " != 0", 
            null,
            null
        );

        List<String> songs = new ArrayList<String>();
        while(music.moveToNext()){
            songs.add(music.getString(0) + ":" + music.getString(1) + ":" +  music.getString(2) + ":" +  music.getString(3) + ":" +  music.getString(4));
        }

        return songs;
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
