package app.parkhill.app

import android.app.Application
import android.util.Log
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import app.parkhill.cache.EntryCache
import app.parkhill.devtools.AppDevTools
import app.parkhill.environment.ServiceBinding
import app.parkhill.navigation.AppCoordinator
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Builds the services and the coordinator once per process, starts launch,
 * and reports the app moving to and from the background.
 */
class ParkHillApplication : Application() {
    lateinit var coordinator: AppCoordinator
        private set

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onCreate() {
        super.onCreate()
        val environment = ServiceBinding.environment
        Log.i("ParkHill", "Environment ${environment.name}, backend ${environment.backendLabel}")
        val services = AppServices(this, environment)
        val devTools = AppDevTools(this, services)
        devTools.install()
        coordinator = AppCoordinator(
            backend = services.backend,
            auth = services.auth,
            registry = ServiceBinding.makeScreenRegistry(services, devTools.screenTracker),
            cache = EntryCache.standard(filesDir),
            scope = scope,
            locale = { AppLocale.current() },
        )
        scope.launch { coordinator.start() }
        ProcessLifecycleOwner.get().lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onStop(owner: LifecycleOwner) = coordinator.movedToBackground()
            override fun onStart(owner: LifecycleOwner) {
                scope.launch { coordinator.movedToForeground() }
            }
        })
    }
}
