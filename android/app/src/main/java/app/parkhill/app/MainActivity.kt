package app.parkhill.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import app.parkhill.design.ParkHillTheme
import app.parkhill.navigation.AppRoot

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val coordinator = (application as ParkHillApplication).coordinator
        setContent {
            ParkHillTheme { AppRoot(coordinator) }
        }
    }
}
