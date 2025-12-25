# ========= FRv5.2-emulate-disconnect (ROS 7.20.x) =========
# Purpose: Emulate a PPPoE disconnect event for testing purposes.
# This script reads current interface values and global variables,
# logs them, then modifies global variables to simulate a new disconnect.
# This is a testing/debugging utility script.

:local scriptVersion "FRv5.2-emulate"
:local pppInterfaceName "Telekom-pppoe-out"

:do {

  :log info ($scriptVersion.": === Starting disconnect emulation ===")

  # ----- Declare global variables -----
  :global frPrevLastUp
  :global tgText
  :global frCandUp
  :global frCandSeen
  :global frNotifiedUp
  :global frNotifiedDowns
  :global frBusy

  # ----- Find PPPoE interface -----
  :local pppInterfaceId [/interface find where name=$pppInterfaceName]
  :if ([:len $pppInterfaceId]=0) do={
    :log warning ($scriptVersion.": iface not found: ".$pppInterfaceName)
    :return
  }

  # ----- Read current interface values -----
  :local lastLinkUpTime   "" ; :do { :set lastLinkUpTime   [/interface get $pppInterfaceId last-link-up-time]   } on-error={ :set lastLinkUpTime   "error" }
  :local lastLinkDownTime "" ; :do { :set lastLinkDownTime [/interface get $pppInterfaceId last-link-down-time] } on-error={ :set lastLinkDownTime "error" }
  :local linkDownCount    "" ; :do { :set linkDownCount    [/interface get $pppInterfaceId link-downs]          } on-error={ :set linkDownCount    "error" }

  # ----- Log current interface values -----
  :log info ($scriptVersion.": --- Current interface values ---")
  :log info ($scriptVersion.": Interface: ".$pppInterfaceName)
  :log info ($scriptVersion.": last-link-up-time: ".$lastLinkUpTime)
  :log info ($scriptVersion.": last-link-down-time: ".$lastLinkDownTime)
  :log info ($scriptVersion.": link-downs: ".[:tostr $linkDownCount])

  # ----- Log current global variables -----
  :log info ($scriptVersion.": --- Current global variables ---")
  :log info ($scriptVersion.": frPrevLastUp: ".[:tostr $frPrevLastUp])
  :log info ($scriptVersion.": frNotifiedUp: ".[:tostr $frNotifiedUp])
  :log info ($scriptVersion.": frNotifiedDowns: ".[:tostr $frNotifiedDowns])
  :log info ($scriptVersion.": frCandUp: ".[:tostr $frCandUp])
  :log info ($scriptVersion.": frCandSeen: ".[:tostr $frCandSeen])
  :log info ($scriptVersion.": frBusy: ".[:tostr $frBusy])
  :log info ($scriptVersion.": tgText: ".[:tostr $tgText])

  # ----- Emulate disconnect by modifying global variables -----
  :log info ($scriptVersion.": --- Emulating disconnect ---")

  # Calculate new values for emulation
  :local newDownCount 0
  :if ([:typeof $linkDownCount] = "num") do={
    :set newDownCount ($linkDownCount + 1)
  } else={
    :do { :set newDownCount ([:tonum $linkDownCount] + 1) } on-error={ :set newDownCount 1 }
  }

  # Get current time for emulated timestamps
  :local currentTime [/system clock get time]
  :local currentDate [/system clock get date]
  :local emulatedTime ($currentDate." ".$currentTime)

  # Update global variables to trigger notification on next script run
  # Reset frNotifiedUp and frNotifiedDowns to force detection of "change"
  :set frNotifiedUp ""
  :set frNotifiedDowns ""
  
  # Reset debounce counters
  :set frCandUp ""
  :set frCandSeen 0
  
  # Clear busy flag
  :set frBusy false

  # ----- Log new values -----
  :log info ($scriptVersion.": --- New global variable values ---")
  :log info ($scriptVersion.": frNotifiedUp: ".[:tostr $frNotifiedUp]." (cleared)")
  :log info ($scriptVersion.": frNotifiedDowns: ".[:tostr $frNotifiedDowns]." (cleared)")
  :log info ($scriptVersion.": frCandUp: ".[:tostr $frCandUp]." (cleared)")
  :log info ($scriptVersion.": frCandSeen: ".[:tostr $frCandSeen]." (reset to 0)")
  :log info ($scriptVersion.": frBusy: ".[:tostr $frBusy]." (cleared)")

  :log info ($scriptVersion.": === Disconnect emulation completed ===")
  :log info ($scriptVersion.": Next run of uptime-watch script will detect this as a new event")

} on-error={
  :log warning ($scriptVersion.": caught-error during emulation")
}

# ========= /FRv5.1-emulate-disconnect =========
