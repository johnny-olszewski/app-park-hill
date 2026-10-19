package app.parkhill.app

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import app.parkhill.environment.ServiceBinding

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val environment = ServiceBinding.environment
        Log.i("ParkHill", "Environment ${environment.name}, backend ${environment.backendLabel}")
        setContent {
            MaterialTheme {
                // Placeholder until the coordinator and registry exist (AND-003).
                Surface(Modifier.fillMaxSize()) { Box(Modifier.fillMaxSize()) }
            }
        }
    }
}
