package app.parkhill.navigation

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import app.parkhill.R
import app.parkhill.design.AssetProvider
import app.parkhill.design.ParkHill
import app.parkhill.screens.launch.LaunchErrorScreen
import kotlinx.coroutines.launch

/**
 * The signed-in destination: the backend's tabs in the Material navigation
 * bar, each with its own stack (guide 5.5: brand color and type only). Only
 * the selected tab is composed; each tab's saveable state is kept.
 */
@Composable
fun SignedInShell(
    shell: ShellCoordinator,
    signOut: () -> Unit, // TEMPORARY(EP-04): remove with IOS-015/AND-015
) {
    val scope = rememberCoroutineScope()
    when (shell.state) {
        ShellState.Loading -> Box(Modifier.fillMaxSize().background(ParkHill.colors.surface), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = ParkHill.colors.ink)
        }
        ShellState.Error -> LaunchErrorScreen { scope.launch { shell.retry() } }
        ShellState.Tabs -> {
            val selected = shell.tabs.firstOrNull { it.id == shell.selectedTabId } ?: shell.tabs.first()
            val saveableState = rememberSaveableStateHolder()
            Scaffold(
                containerColor = ParkHill.colors.surface,
                bottomBar = {
                    NavigationBar(containerColor = ParkHill.colors.surface) {
                        shell.tabs.forEach { tab ->
                            NavigationBarItem(
                                selected = tab === selected,
                                onClick = { shell.selectedTabId = tab.id },
                                icon = { Icon(painterResource(AssetProvider.tabIcon(tab.iconKey)), contentDescription = null) },
                                label = { Text(tab.title) },
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = ParkHill.colors.ink,
                                    selectedTextColor = ParkHill.colors.ink,
                                    indicatorColor = ParkHill.colors.surfaceSunken,
                                    unselectedIconColor = ParkHill.colors.inkMuted,
                                    unselectedTextColor = ParkHill.colors.inkMuted,
                                ),
                                modifier = Modifier.testTag("tab.${tab.id}"),
                            )
                        }
                    }
                },
            ) { padding ->
                Box(Modifier.padding(padding)) {
                    saveableState.SaveableStateProvider(selected.id) {
                        TabRoot(
                            selected,
                            signOut = if (selected.id == "home") signOut else null, // TEMPORARY(EP-04): remove with IOS-015/AND-015
                        )
                    }
                }
            }
        }
    }
}

/** One tab: the top of its stack under a top app bar titled with the tab's title, and its sheet. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TabRoot(
    tab: TabCoordinator,
    signOut: (() -> Unit)?, // TEMPORARY(EP-04): remove with IOS-015/AND-015
) {
    BackHandler(enabled = tab.path.isNotEmpty()) { tab.pop() }
    Column(Modifier.fillMaxSize()) {
        LargeTopAppBar(
            title = { Text(tab.title, style = ParkHill.heading, modifier = Modifier.testTag("tab.title")) },
            actions = {
                if (signOut != null) { // TEMPORARY(EP-04): remove with IOS-015/AND-015
                    TextButton(onClick = signOut, modifier = Modifier.testTag("home.signOut")) { // TEMPORARY(EP-04): remove with IOS-015/AND-015
                        Text(stringResource(R.string.shell_sign_out), color = ParkHill.colors.ink) // TEMPORARY(EP-04): remove with IOS-015/AND-015
                    } // TEMPORARY(EP-04): remove with IOS-015/AND-015
                } // TEMPORARY(EP-04): remove with IOS-015/AND-015
            },
            colors = TopAppBarDefaults.largeTopAppBarColors(
                containerColor = ParkHill.colors.surface,
                scrolledContainerColor = ParkHill.colors.surface,
                titleContentColor = ParkHill.colors.ink,
            ),
        )
        Box(Modifier.weight(1f)) {
            (tab.path.lastOrNull()?.screen ?: tab.root).content()
        }
    }
    tab.presented?.let { route ->
        ModalBottomSheet(onDismissRequest = tab::dismiss, containerColor = ParkHill.colors.surface) {
            route.screen.content()
        }
    }
}
