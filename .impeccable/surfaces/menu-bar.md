# Menu-bar panel

Mode: Operate. The user explicitly requested Apple-native Liquid Glass across the entire menu-bar panel, with iOS-style controls and truthful closed-lid success/error states. Implement directly in native SwiftUI using the supplied visual language and existing feature scope.

## Direction contract

THESIS: A compact glass control panel for starting an awake session and knowing whether lid protection is actually active.

OWN-WORLD: System typography, adaptive native glass, capsule actions, monochrome SF Symbols, blue primary action, green confirmed protection, secondary-gray notices and warnings. Communicate warnings with symbols and complete text. Respect accessibility settings and provide material fallbacks before macOS 26.

STORY: Choose Timer, Until, or Unlimited; set the duration or end time; start. Until offers one editable clock, a Today/Tomorrow and remaining-duration summary, and three relative-time shortcuts. The session becomes the focus. Closed-lid status confirms protection separately from the timer.

FIRST VIEWPORT: 360-point panel; compact brand/status header and utility menu; segmented modes; Timer's large inline duration editor and six glass presets, or Until's single native time editor and three glass shortcuts; full-width primary action; dedicated glass closed-lid control/status.

FORM: User-pinned Apple Liquid Glass, code-first in the existing macOS utility. Preserve native pointer, keyboard, menu, and helper behavior. Explicit state animation stays within switches and the Timer / Until / Unlimited selector. The selector's persistent glass capsule slides strictly side-to-side beneath stationary labels, with no vertical travel; its track remains 44 points high. Panel content does not animate, and Reduce Motion suppresses the control transitions.

STATUS: Show one secondary-gray session notice. Keep closed-lid readiness separate: issue → confirmed active → checking → approval → setup → off → starting/ready. Only verified active protection earns green “Active” / “You can close the lid.” Preserve full gray warning text and offer “Repair helper” for transport or update failures without bypassing readiness or safety checks.

FINISH: Build and sign, inspect idle/active/error states, verify controls and truthful helper status, complete independent native review and document the implemented design.
