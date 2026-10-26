package app.parkhill.navigation

import app.parkhill.cache.ScreenCache
import app.parkhill.contract.CallAction
import app.parkhill.contract.CallActionOnSuccess
import app.parkhill.contract.CallActionType
import app.parkhill.contract.CommunityGroupData
import app.parkhill.contract.CommunityHomeData
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem
import app.parkhill.screens.community.CommunityHomeState
import app.parkhill.services.auth.FakeAuthService
import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.ContractJson
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** `call` actions from the recorded responses: confirmation, the call and `on_success`, and refusals (AND-027 AC1, AC3, AC5). */
class CallActionsTest {
    private val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!
    private val backend = StubBackendService { throw BackendError.Server }
    private val registry = ScreenRegistry().apply { registerSharedScreens(FakeAuthService()) }
    private val context = ScreenContext(backend, registry, ScreenCache(Files.createTempDirectory("screens").toFile())) { "en" }

    private fun recorded(name: String): ScreenEnvelope =
        ContractJson.decodeFromString(ScreenEnvelope.serializer(), File(root, name).readText())

    private fun home(persona: String) = recorded("$persona/get_screen.community.home.json")

    private fun homeData(envelope: ScreenEnvelope) = ContractJson.decodeFromJsonElement(CommunityHomeData.serializer(), envelope.data)

    private fun tab(root: ScreenEnvelope) = TabCoordinator(TabItem("community", "Community", "tab.community", root), context, eagerScope())

    /** The leader's remove action on Ana Ruiz's row. */
    private fun removeAna(): CallAction =
        homeData(home("leader")).group!!.members.first { it.title == "Ana Ruiz" }.remove!!.action as CallAction

    private val tuesdayNight = "d44d5b87-37ce-5db5-9e33-43f477b42f1e"
    private val memberTwosGroup = recorded("member_two/get_screen.community.group@group_id=$tuesdayNight.json")

    /** member_two's Community home with Tuesday Night Group pushed and loaded. */
    private suspend fun memberTwoWithGroupPushed(): Pair<TabCoordinator, ScreenModel> {
        backend.screen = { key, _ -> if (key == "community.group") memberTwosGroup else home("member_two") }
        val tab = tab(home("member_two"))
        val row = homeData(home("member_two")).myGroups!!.rows.first { it.groupId == tuesdayNight }
        tab.actions.from(tab.root).perform(row.action)
        val pushed = tab.path.single().screen
        pushed.load()
        return tab to pushed
    }

    private fun leave(group: ScreenEnvelope): CallAction =
        ContractJson.decodeFromJsonElement(CommunityGroupData.serializer(), group.data).leave!!.action as CallAction

    // AC1: the backend's confirmation comes first; cancelling calls nothing.

    @Test
    fun aCallWithAConfirmationWaitsForItAndCancellingCallsNothing() {
        val tab = tab(home("leader"))
        val remove = removeAna()
        tab.actions.from(tab.root).perform(remove)

        val pending = tab.pendingCall!!
        assertEquals("Remove Ana Ruiz?", pending.action.confirm?.title)
        assertEquals(remove.confirm, pending.action.confirm)
        assertTrue(backend.calls.isEmpty())

        tab.cancelCall()
        assertNull(tab.pendingCall)
        assertTrue(backend.calls.isEmpty())
        assertTrue(backend.screenCalls.isEmpty())
    }

    @Test
    fun confirmingCallsTheFunctionWithItsParamsThenRefreshesTheScreen() {
        backend.screen = { _, _ -> home("leader") }
        val tab = tab(home("leader"))
        val remove = removeAna()
        tab.actions.from(tab.root).perform(remove)
        tab.confirmCall()

        assertNull(tab.pendingCall)
        assertEquals(listOf(Triple("remove_member", remove.params, "en")), backend.calls)
        assertEquals(listOf("community.home"), backend.screenCalls.map { it.first })
        assertNull(tab.message)
    }

    @Test
    fun aCallWithoutAConfirmationIsMadeAtOnceAndNoneDoesNothing() {
        val tab = tab(home("leader"))
        val call = CallAction(CallActionType.CALL, "some_function", JsonObject(mapOf("x" to JsonPrimitive("1"))), onSuccess = CallActionOnSuccess.NONE)
        tab.actions.from(tab.root).perform(call)

        assertNull(tab.pendingCall)
        assertEquals("some_function", backend.calls.single().first)
        assertTrue(backend.screenCalls.isEmpty())
        assertTrue(ScreenActions().canPerform(call))
    }

    // AC3: leaving a pushed group closes it and refreshes below; on Community home it refreshes home.

    @Test
    fun leavingAPushedGroupClosesItAndRefreshesTheScreenBelow() = runTest {
        val (tab, pushed) = memberTwoWithGroupPushed()
        backend.screenCalls.clear()
        tab.actions.from(pushed).perform(leave(memberTwosGroup))
        assertEquals("Leave Tuesday Night Group?", tab.pendingCall?.action?.confirm?.title)
        tab.confirmCall()

        assertEquals("leave_group", backend.calls.single().first)
        assertEquals(tuesdayNight, backend.calls.single().second["p_group_id"]?.jsonPrimitive?.content)
        assertTrue(tab.path.isEmpty())
        assertEquals(listOf("community.home"), backend.screenCalls.map { it.first })
        assertNull(tab.message)
    }

    @Test
    fun leavingOnCommunityHomeRefreshesHomeToItsNewState() {
        // Mock responses are static; attendee's home stands in for member_one's after leaving.
        backend.screen = { _, _ -> home("attendee") }
        val tab = tab(home("member_one"))
        tab.actions.from(tab.root).perform(homeData(home("member_one")).group!!.leave!!.action)
        tab.confirmCall()

        assertEquals("leave_group", backend.calls.single().first)
        assertEquals(home("attendee"), tab.root.envelope)
        assertTrue(CommunityHomeState.of(homeData(tab.root.envelope!!)) is CommunityHomeState.Empty)
        assertTrue(tab.path.isEmpty())
    }

    // AC5: a refused call shows its message and refreshes; a refresh that finds the screen gone shows only that.

    @Test
    fun aRefusedCallRefreshesTheScreenAndShowsTheRefusal() {
        backend.screen = { _, _ -> home("leader") }
        backend.callResult = { throw BackendError.ActionRefused("You can't make this change anymore.") }
        val tab = tab(home("leader"))
        tab.actions.from(tab.root).perform(removeAna())
        tab.confirmCall()

        assertEquals("You can't make this change anymore.", tab.message?.text)
        assertEquals(listOf("community.home"), backend.screenCalls.map { it.first })
    }

    @Test
    fun aRefusedCallWhoseRefreshIsRefusedShowsOnlyTheLostAccessMessage() = runTest {
        val (tab, pushed) = memberTwoWithGroupPushed()
        backend.callResult = { throw BackendError.ActionRefused("You can't make this change anymore.") }
        backend.screen = { key, _ ->
            if (key == "community.group") throw BackendError.ScreenUnavailable("You're no longer in this group") else home("member_two")
        }
        tab.actions.from(pushed).perform(leave(memberTwosGroup))
        tab.confirmCall()

        assertEquals("You're no longer in this group", tab.message?.text)
        assertTrue(tab.path.isEmpty())
        assertEquals("community.home", backend.screenCalls.last().first)
    }

    @Test
    fun anotherFailureChangesNothing() = runTest {
        val (tab, pushed) = memberTwoWithGroupPushed()
        backend.screenCalls.clear()
        backend.callResult = { throw BackendError.Network }
        tab.actions.from(pushed).perform(leave(memberTwosGroup))
        tab.confirmCall()

        assertEquals(1, tab.path.size)
        assertTrue(backend.screenCalls.isEmpty())
        assertNull(tab.message)
    }
}
