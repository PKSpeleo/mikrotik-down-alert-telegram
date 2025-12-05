# ========= FRv5.0-reset-vars (ROS 7.20.x) =========
# Purpose: Reset (unset) all global variables used by the uptime-watch script
# to emulate router reboot and observe script behavior during testing.
# This is a testing/debugging utility script.

:local scriptVersion "FRv5.0-reset"

:do {

  :log info ($scriptVersion.": starting global variables reset")

  # Declare global variables
  :global frPrevLastUp
  :global tgText
  :global frCandUp
  :global frCandSeen
  :global frNotifiedUp
  :global frBusy

  :local resetCount 0

  # Reset (unset) each global variable by setting it to nil
  :do {
    :if ([:typeof $frPrevLastUp] != "nil") do={
      :set frPrevLastUp
      :set resetCount ($resetCount + 1)
      :log info ($scriptVersion.": reset 'frPrevLastUp'")
    } else={
      :log info ($scriptVersion.": 'frPrevLastUp' already nil")
    }
  } on-error={ :log warning ($scriptVersion.": failed to reset 'frPrevLastUp'") }

  :do {
    :if ([:typeof $tgText] != "nil") do={
      :set tgText
      :set resetCount ($resetCount + 1)
      :log info ($scriptVersion.": reset 'tgText'")
    } else={
      :log info ($scriptVersion.": 'tgText' already nil")
    }
  } on-error={ :log warning ($scriptVersion.": failed to reset 'tgText'") }

  :do {
    :if ([:typeof $frCandUp] != "nil") do={
      :set frCandUp
      :set resetCount ($resetCount + 1)
      :log info ($scriptVersion.": reset 'frCandUp'")
    } else={
      :log info ($scriptVersion.": 'frCandUp' already nil")
    }
  } on-error={ :log warning ($scriptVersion.": failed to reset 'frCandUp'") }

  :do {
    :if ([:typeof $frCandSeen] != "nil") do={
      :set frCandSeen
      :set resetCount ($resetCount + 1)
      :log info ($scriptVersion.": reset 'frCandSeen'")
    } else={
      :log info ($scriptVersion.": 'frCandSeen' already nil")
    }
  } on-error={ :log warning ($scriptVersion.": failed to reset 'frCandSeen'") }

  :do {
    :if ([:typeof $frNotifiedUp] != "nil") do={
      :set frNotifiedUp
      :set resetCount ($resetCount + 1)
      :log info ($scriptVersion.": reset 'frNotifiedUp'")
    } else={
      :log info ($scriptVersion.": 'frNotifiedUp' already nil")
    }
  } on-error={ :log warning ($scriptVersion.": failed to reset 'frNotifiedUp'") }

  :do {
    :if ([:typeof $frBusy] != "nil") do={
      :set frBusy
      :set resetCount ($resetCount + 1)
      :log info ($scriptVersion.": reset 'frBusy'")
    } else={
      :log info ($scriptVersion.": 'frBusy' already nil")
    }
  } on-error={ :log warning ($scriptVersion.": failed to reset 'frBusy'") }

  # Summary
  :log info ($scriptVersion.": completed - reset ".([:tostr $resetCount])." variables")

} on-error={
  :log warning ($scriptVersion.": caught-error during reset")
}

# ========= /FRv5.0-reset-vars =========
