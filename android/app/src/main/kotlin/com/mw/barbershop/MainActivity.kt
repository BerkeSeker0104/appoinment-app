package com.mw.barbershop

import io.flutter.embedding.android.FlutterFragmentActivity
import androidx.activity.enableEdgeToEdge
import android.os.Bundle

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
