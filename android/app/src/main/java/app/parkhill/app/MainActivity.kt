package app.parkhill.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import app.parkhill.navigation.AppRoot

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val coordinator = (application as ParkHillApplication).coordinator
        setContent {
            MaterialTheme {
                Surface(Modifier.fillMaxSize()) { AppRoot(coordinator) }
            }
        }
    }
}
