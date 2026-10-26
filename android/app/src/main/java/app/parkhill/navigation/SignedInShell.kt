package app.parkhill.navigation

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.IconButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import app.parkhill.R
import app.parkhill.contract.CallActionRole
import app.parkhill.design.AssetProvider
import app.parkhill.design.ParkHill
import app.parkhill.screens.launch.LaunchErrorScreen
import kotlinx.coroutines.launch

/**
 * The signed-in destination: the backend's tabs in the Material navigation
 * bar, each with its own stack (guide 5.5: brand color and type only), and
 * the selected tab's full-screen cover over all of it. Only the selected tab
 * is composed; each tab's saveable state is kept.
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
            val snackbar = remember(selected) { SnackbarHostState() }
            TabMessages(selected, snackbar)
            CallConfirmationDialog(selected)
            Box(Modifier.fillMaxSize()) {
                Scaffold(
                    containerColor = ParkHill.colors.surface,
                    // Over the cover when one is open; otherwise over the tab.
                    snackbarHost = { if (selected.cover == null) MessageHost(snackbar) },
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
                FullScreenCover(selected, snackbar)
            }
        }
    }
}

/** Shows the tab's messages, such as the lost-access message, one at a time as a `Snackbar` (guide 5.5). */
@Composable
private fun TabMessages(tab: TabCoordinator, snackbar: SnackbarHostState) {
    val message = tab.message ?: return
    LaunchedEffect(message) {
        snackbar.showSnackbar(message.text)
        tab.messageShown(message)
    }
}

/**
 * The backend's confirmation for the tab's pending `call` (guide 5.5: a
 * Material alert dialog), its confirm button in the danger color when the
 * call is destructive. Cancelling, or dismissing the dialog, calls nothing.
 */
@Composable
private fun CallConfirmationDialog(tab: TabCoordinator) {
    val pending = tab.pendingCall ?: return
    val confirm = pending.action.confirm ?: return
    val destructive = pending.action.role == CallActionRole.DESTRUCTIVE
    AlertDialog(
        onDismissRequest = tab::cancelCall,
        title = { Text(confirm.title, modifier = Modifier.testTag("confirm.title")) },
        text = { Text(confirm.message, modifier = Modifier.testTag("confirm.message")) },
        confirmButton = {
            TextButton(onClick = tab::confirmCall, modifier = Modifier.testTag("confirm.confirm")) {
                Text(confirm.confirmLabel, color = if (destructive) ParkHill.colors.danger else ParkHill.colors.ink)
            }
        },
        dismissButton = {
            TextButton(onClick = tab::cancelCall, modifier = Modifier.testTag("confirm.cancel")) {
                Text(confirm.cancelLabel, color = ParkHill.colors.ink)
            }
        },
        containerColor = ParkHill.colors.surface,
        titleContentColor = ParkHill.colors.ink,
        textContentColor = ParkHill.colors.ink,
    )
}

/** Where a tab's `Snackbar` appears. */
@Composable
internal fun MessageHost(snackbar: SnackbarHostState) {
    SnackbarHost(snackbar) { data -> Snackbar(data, modifier = Modifier.testTag("message")) }
}

/**
 * One tab: the top of its stack under a top app bar, and its sheet. The root
 * shows the tab's title as a large title; a pushed screen shows its own
 * title with a back button. System back pops inside the tab's cover first.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TabRoot(
    tab: TabCoordinator,
    signOut: (() -> Unit)?, // TEMPORARY(EP-04): remove with IOS-015/AND-015
) {
    BackHandler(enabled = tab.path.isNotEmpty() || tab.cover != null) { tab.back() }
    val top = tab.path.lastOrNull()
    CompositionLocalProvider(LocalScreenActions provides tab.actions) {
        Column(Modifier.fillMaxSize()) {
            if (top == null) {
                LargeTopAppBar(
                    title = { Text(tab.title, style = ParkHill.heading, modifier = Modifier.testTag("tab.title")) },
                    navigationIcon = { tab.root.chrome?.navigationIcon?.invoke() },
                    actions = {
                        ScreenBarActions(tab.root)
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
                        navigationIconContentColor = ParkHill.colors.ink,
                        actionIconContentColor = ParkHill.colors.ink,
                    ),
                )
            } else {
                ScreenTopBar(top.screen) { BackButton { tab.pop() } }
            }
            ScreenStackContent(tab.stack, Modifier.weight(1f))
        }
        TabSheet(tab)
    }
}

/**
 * The tab's sheet (guide 5.5: a Material modal bottom sheet), over the cover
 * while one is open, since a sheet is its own window. It opens fully over a
 * loading state; dragging it down, like its Cancel, closes it handing back
 * nothing. Its screen has no pull to refresh: dragging down is for closing.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TabSheet(tab: TabCoordinator) {
    val sheet = tab.presented ?: return
    ModalBottomSheet(
        onDismissRequest = tab::dismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = ParkHill.colors.surface,
        modifier = Modifier.testTag("sheet"),
    ) {
        key(sheet.route.id) {
            CompositionLocalProvider(LocalSheetActions provides tab.sheetActions) {
                ScreenHost(sheet.screen, refreshable = false)
            }
        }
    }
}

/** A backend screen's top app bar: its own title, `navigationIcon` unless the screen replaces it, and its toolbar ([ScreenBarActions]). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ScreenTopBar(screen: ScreenModel, navigationIcon: @Composable () -> Unit) {
    TopAppBar(
        title = {
            Text(
                (screen.state as? ScreenState.Showing)?.screen?.title.orEmpty(),
                style = ParkHill.heading.copy(fontSize = 20.sp),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.testTag("screen.title"),
            )
        },
        navigationIcon = { (screen.chrome?.navigationIcon ?: navigationIcon)() },
        actions = { ScreenBarActions(screen) },
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = ParkHill.colors.surface,
            scrolledContainerColor = ParkHill.colors.surface,
            titleContentColor = ParkHill.colors.ink,
            navigationIconContentColor = ParkHill.colors.ink,
            actionIconContentColor = ParkHill.colors.ink,
        ),
    )
}

/** The platform back button of a pushed screen. */
@Composable
internal fun BackButton(onClick: () -> Unit) {
    IconButton(onClick = onClick, modifier = Modifier.testTag("screen.back")) {
        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.navigation_back))
    }
}

/**
 * The top of a stack. Pushed screens slide in from the trailing edge and back
 * out on back, as iOS's navigation stack does (guide 5.5 rule 5). Each
 * screen's saveable state, such as a search field's text, is kept while
 * screens are pushed over it and dropped when it is popped.
 */
@Composable
internal fun ScreenStackContent(stack: ScreenStack, modifier: Modifier = Modifier) {
    val top = stack.path.lastOrNull()
    val saveableState = rememberSaveableStateHolder()
    val shown = stack.path.map { it.id }.toSet()
    val provided = remember { mutableSetOf<Long>() }
    LaunchedEffect(shown) {
        (provided - shown - ROOT_ID).forEach { id ->
            saveableState.removeState(id)
            provided -= id
        }
    }
    AnimatedContent(
        targetState = top,
        transitionSpec = {
            val pushing = (targetState?.id ?: 0L) > (initialState?.id ?: 0L)
            if (pushing) {
                slideInHorizontally { it } togetherWith slideOutHorizontally { -it / 3 }
            } else {
                slideInHorizontally { -it / 3 } togetherWith slideOutHorizontally { it }
            }
        },
        contentKey = { it?.id },
        label = "stack",
        modifier = modifier,
    ) { route ->
        val id = route?.id ?: ROOT_ID
        provided += id
        saveableState.SaveableStateProvider(id) {
            Box(Modifier.fillMaxSize().background(ParkHill.colors.surface)) {
                ScreenHost(route?.screen ?: stack.root)
            }
        }
    }
}

/** The saveable state key of a stack's root; route ids start at 1. */
private const val ROOT_ID = 0L
