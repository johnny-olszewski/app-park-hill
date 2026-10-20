package app.parkhill.design

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextFieldColors
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Park Hill tokens from the wireframes (guide 5.5): brand color and type
 * applied to Material components, matching iOS's `ParkHill/Design`. Headings
 * use the system serif until the brand fonts are bundled.
 */
@Immutable
data class ParkHillColors(
    val surface: Color,
    val surfaceRaised: Color,
    val surfaceSunken: Color,
    val ink: Color,
    val inkMuted: Color,
    val line: Color,
    val fill: Color,
    val onFill: Color,
    val sky: Color,
    val danger: Color,
)

private val Light = ParkHillColors(
    surface = Color(0xFFFDFBF7), surfaceRaised = Color(0xFFFFFFFF), surfaceSunken = Color(0xFFF4F0E8),
    ink = Color(0xFF221F20), inkMuted = Color(0xFF5F6769), line = Color(0xFFCCCCCC),
    fill = Color(0xFF221F20), onFill = Color(0xFFFDFBF7), sky = Color(0xFFA0C6DC), danger = Color(0xFFB3261E),
)

private val Dark = ParkHillColors(
    surface = Color(0xFF221F20), surfaceRaised = Color(0xFF2E2A2B), surfaceSunken = Color(0xFF191718),
    ink = Color(0xFFFDFBF7), inkMuted = Color(0xFFA9B0B2), line = Color(0xFF4A4546),
    fill = Color(0xFFFDFBF7), onFill = Color(0xFF221F20), sky = Color(0xFFA0C6DC), danger = Color(0xFFFF9485),
)

val LocalParkHillColors = staticCompositionLocalOf { Light }

object ParkHill {
    val colors: ParkHillColors @Composable get() = LocalParkHillColors.current

    /** Screen and section headings: the brand serif. */
    val heading = TextStyle(fontFamily = FontFamily.Serif, fontSize = 34.sp, fontWeight = FontWeight.Normal)

    /** Small uppercase labels above fields and lists. */
    val label = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 0.7.sp)

    val shape = RoundedCornerShape(14.dp)
}

@Composable
fun ParkHillTheme(content: @Composable () -> Unit) {
    val colors = if (isSystemInDarkTheme()) Dark else Light
    val scheme = (if (isSystemInDarkTheme()) darkColorScheme() else lightColorScheme()).copy(
        primary = colors.fill, onPrimary = colors.onFill,
        background = colors.surface, onBackground = colors.ink,
        surface = colors.surface, onSurface = colors.ink, onSurfaceVariant = colors.inkMuted,
        outline = colors.inkMuted, error = colors.danger,
    )
    androidx.compose.runtime.CompositionLocalProvider(LocalParkHillColors provides colors) {
        MaterialTheme(colorScheme = scheme, typography = Typography(), content = content)
    }
}

/** Full-width primary button: filled ink with an uppercase, tracked label. */
@Composable
fun PrimaryButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true, leading: @Composable () -> Unit = {}) {
    val colors = ParkHill.colors
    Button(
        onClick = onClick,
        enabled = enabled,
        shape = ParkHill.shape,
        border = BorderStroke(2.dp, if (enabled) colors.fill else colors.inkMuted),
        colors = ButtonDefaults.buttonColors(
            containerColor = colors.fill, contentColor = colors.onFill,
            disabledContainerColor = Color.Transparent, disabledContentColor = colors.inkMuted,
        ),
        modifier = modifier.fillMaxWidth().heightIn(min = 48.dp),
    ) {
        leading()
        Text(text.uppercase(), fontWeight = FontWeight.SemiBold, letterSpacing = 1.2.sp)
    }
}

/** Outlined button that sizes to its label; destructive buttons use the danger color. */
@Composable
fun SecondaryButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, destructive: Boolean = false) {
    val color = if (destructive) ParkHill.colors.danger else ParkHill.colors.ink
    OutlinedButton(
        onClick = onClick,
        shape = ParkHill.shape,
        border = BorderStroke(2.dp, color),
        colors = ButtonDefaults.outlinedButtonColors(contentColor = color),
        modifier = modifier.heightIn(min = 48.dp),
    ) {
        Text(text.uppercase(), fontWeight = FontWeight.SemiBold, letterSpacing = 1.2.sp)
    }
}

/** Material text field colors in the brand's bordered look. */
@Composable
fun brandFieldColors(): TextFieldColors {
    val colors = ParkHill.colors
    return OutlinedTextFieldDefaults.colors(
        focusedContainerColor = colors.surfaceRaised, unfocusedContainerColor = colors.surfaceRaised,
        focusedBorderColor = colors.ink, unfocusedBorderColor = colors.inkMuted,
        errorBorderColor = colors.danger, errorContainerColor = colors.surfaceRaised,
        cursorColor = colors.ink,
    )
}
