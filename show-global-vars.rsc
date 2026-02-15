# ========= FRv5.3-show-vars (ROS 7.20.x) =========
# Purpose: Display all global variables used by the uptime-watch script
# in the system log for debugging and monitoring purposes.
# This is a testing/debugging utility script.

:local scriptVersion "FRv5.3-show"

:do {

  :log info ($scriptVersion.": === Global variables status ===")

  # Declare global variables
  :global frPrevLastUp
  :global tgText
  :global frCandUp
  :global frCandSeen
  :global frNotifiedUp
  :global frNotifiedDowns
  :global frBusy

  # Log each global variable with its type and value
  :log info ($scriptVersion.": frPrevLastUp     = ".[:tostr $frPrevLastUp]." (type: ".[:typeof $frPrevLastUp].")")
  :log info ($scriptVersion.": frNotifiedUp     = ".[:tostr $frNotifiedUp]." (type: ".[:typeof $frNotifiedUp].")")
  :log info ($scriptVersion.": frNotifiedDowns  = ".[:tostr $frNotifiedDowns]." (type: ".[:typeof $frNotifiedDowns].")")
  :log info ($scriptVersion.": frCandUp         = ".[:tostr $frCandUp]." (type: ".[:typeof $frCandUp].")")
  :log info ($scriptVersion.": frCandSeen       = ".[:tostr $frCandSeen]." (type: ".[:typeof $frCandSeen].")")
  :log info ($scriptVersion.": frBusy           = ".[:tostr $frBusy]." (type: ".[:typeof $frBusy].")")
  :log info ($scriptVersion.": tgText           = ".[:tostr $tgText]." (type: ".[:typeof $tgText].")")

  :log info ($scriptVersion.": === End of global variables ===")

} on-error={
  :log warning ($scriptVersion.": caught-error while reading variables")
}

# ========= /FRv5.3-show-vars =========
