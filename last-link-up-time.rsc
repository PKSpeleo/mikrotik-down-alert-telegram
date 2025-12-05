# ========= FRv4.0d-uptime-watch (ROS 7.20.x) =========
# Purpose: watch for changes of last-link-up-time on the PPPoE interface (with debounce)
# and send a notification to Telegram.
# Telegram message format (must stay exactly the same):
# <ver>: <iface>
# Total downs: <downs>
# Last DOWN: <lastDown>
# Last UP:        <lastUp>

:local scriptVersion "FRv4.0d"     # Script version label (used in logs and message)
:local pppInterfaceName "Telekom-pppoe-out"  # Name of the PPPoE interface to monitor

# Telegram (minimal URL encoding: spaces and \n)
:local telegramBotToken "xxx"
:local telegramChatId  "xxx"

# Global variables (persist between runs; do not rename to keep compatibility)
:global frPrevLastUp     # last read last-link-up-time value (as in the original script)
:global tgText           # text of the last Telegram message (for external debugging/logging)

# Anti-duplicates and race protection (debounce + mutex)
:global frCandUp         # candidate for a stable last-link-up-time value
:global frCandSeen       # how many times in a row frCandUp has been seen
:global frNotifiedUp     # last-link-up-time value that has already been sent to Telegram
:global frBusy           # flag that script is already running

:do {

  # ----- Mutex: prevent parallel script execution -----
  :if ([:typeof $frBusy] != "nil" && $frBusy=true) do={ :return }
  :set frBusy true

  # ----- Find PPPoE interface -----
  :local pppInterfaceId [/interface find where name=$pppInterfaceName]
  :if ([:len $pppInterfaceId]=0) do={
    :set frBusy false
    :log warning ($scriptVersion.": iface not found: ".$pppInterfaceName)
    :return
  }

  # ----- Current interface field values (with error protection) -----
  :local lastLinkUpTime   "" ; :do { :set lastLinkUpTime   [/interface get $pppInterfaceId last-link-up-time]   } on-error={ :set lastLinkUpTime   "" }
  :local lastLinkDownTime "" ; :do { :set lastLinkDownTime [/interface get $pppInterfaceId last-link-down-time] } on-error={ :set lastLinkDownTime "" }
  :local linkDownCount    "" ; :do { :set linkDownCount    [/interface get $pppInterfaceId link-downs]          } on-error={ :set linkDownCount    "" }

  # ----- Debounce structures initialization -----
  :if ([:typeof $frCandUp] = "nil" || [:len [:tostr $frCandUp]] = 0) do={ :set frCandUp "" }
  :if ([:typeof $frCandSeen] = "nil" || [:len [:tostr $frCandSeen]] = 0) do={ :set frCandSeen 0 }
  :if ([:typeof $frNotifiedUp] = "nil") do={ :set frNotifiedUp "" }

  # ----- Debounce last-link-up-time (two identical reads in a row) -----
  :if ([:len $lastLinkUpTime] > 0) do={
    :if ($frCandUp = $lastLinkUpTime) do={
      :set frCandSeen ($frCandSeen + 1)
    } else={
      :set frCandUp $lastLinkUpTime
      :set frCandSeen 1
    }
  } else={
    :set frCandSeen 0
  }

  # ----- Change detection (and first run).
  # Do not send a message until last-link-up-time is stable in at least two reads. -----
  :local isLastLinkUpTimeChanged false
  :if ([:len $lastLinkUpTime] > 0) do={
    :if ([:len [:tostr $frNotifiedUp]] = 0) do={
      :if ([:tonum $frCandSeen] >= 2) do={ :set isLastLinkUpTimeChanged true }
    } else={
      :if ($frNotifiedUp != $lastLinkUpTime) do={
        :if ([:tonum $frCandSeen] >= 2) do={ :set isLastLinkUpTimeChanged true }
      }
    }
  }

  :if ($isLastLinkUpTimeChanged) do={

    # ----- Build message in the exact required format -----
    :local telegramMessage ($scriptVersion.": " . $pppInterfaceName . "\n" . \
                            "Total downs: " . $linkDownCount . "\n" . \
                            "Last DOWN: " . $lastLinkDownTime . "\n" . \
                            "Last UP:        " . $lastLinkUpTime)

    :set tgText $telegramMessage

    # Mini-encoder (spaces and line breaks)
    :local plainText $telegramMessage
    :local encodedText ""
    :for i from=0 to=([:len $plainText]-1) do={
      :local ch [:pick $plainText $i ($i+1)]
      :if ($ch=" ") do={ :set encodedText ($encodedText . "%20") } else={
        :if ($ch="\n") do={ :set encodedText ($encodedText . "%0A") } else={ :set encodedText ($encodedText . $ch) }
      }
    }

    :local url ("https://api.telegram.org/bot" . $telegramBotToken . "/sendMessage?chat_id=" . $telegramChatId . "&text=" . $encodedText . "&disable_web_page_preview=1")
    :do { /tool fetch url=$url keep-result=no http-method=get } on-error={ :log warning ($scriptVersion.": tg send failed") }
    :log info ($scriptVersion.": UP - notified")

    # Store the last sent last-link-up-time value (anti-duplicate)
  :set frNotifiedUp $lastLinkUpTime
  }

  # Store the last read value (compatibility with the original script)
  :set frPrevLastUp $lastLinkUpTime

  # Release mutex
  :set frBusy false

} on-error={
  :set frBusy false
  :log warning ($scriptVersion.": caught-error")
}

# ========= /FRv4.0d-uptime-watch =========