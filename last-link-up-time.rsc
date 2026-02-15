# ========= FRv5.3-uptime-watch (ROS 7.20.x) =========
# Purpose: watch for changes of last-link-up-time on the PPPoE interface (with debounce)
# and send a notification to Telegram.
# Telegram message format (must stay exactly the same):
# <ver>: <iface>
# Total downs: <downs>
# Last DOWN: <lastDown>
# Last UP:        <lastUp>

:local scriptVersion "FRv5.3"
:local pppInterfaceName "Telekom-pppoe-out"

# Debounce configuration: minimum number of consecutive stable readings required
:local debounceThreshold 2

# Telegram (minimal URL encoding: spaces and \n)
:local telegramBotToken "xxx"
:local telegramChatId  "xxx"

# Global variables (persist between runs; do not rename to keep compatibility)
:global frPrevLastUp
:global tgText

# Anti-duplicates and race protection (debounce + mutex)
:global frCandUp
:global frCandSeen
:global frNotifiedUp
:global frNotifiedDowns
:global frBusy

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
  :local isRunning        false; :do { :set isRunning        [/interface get $pppInterfaceId running]             } on-error={ :set isRunning        false }

  # ----- Debounce structures initialization -----
  :if ([:typeof $frCandUp] = "nil" || [:len [:tostr $frCandUp]] = 0) do={ :set frCandUp "" }
  :if ([:typeof $frCandSeen] = "nil" || [:len [:tostr $frCandSeen]] = 0) do={ :set frCandSeen 0 }
  :if ([:typeof $frNotifiedUp] = "nil") do={ :set frNotifiedUp "" }
  :if ([:typeof $frNotifiedDowns] = "nil") do={ :set frNotifiedDowns "" }

  # ----- Debounce last-link-up-time (require stable readings) -----
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

  # ----- Change detection (and first run) -----
  # Do not send a message until last-link-up-time is stable for debounceThreshold reads.
  # Require BOTH time AND counter to change to avoid false positives from time interpretation differences.
  :local isLastLinkUpTimeChanged false
  :local hasValidUpTime ([:len $lastLinkUpTime] > 0)
  :local hasValidDownCount ([:len [:tostr $linkDownCount]] > 0)
  :local isStable ($frCandSeen >= $debounceThreshold)
  :local isFirstRun ([:len [:tostr $frNotifiedUp]] = 0)
  :local hasTimeChanged ($frNotifiedUp != $lastLinkUpTime)
  :local hasCountChanged ([:tostr $frNotifiedDowns] != [:tostr $linkDownCount])
  
  :if ($hasValidUpTime && $hasValidDownCount && $isStable && $isRunning) do={
    :if ($isFirstRun || ($hasTimeChanged && $hasCountChanged)) do={
      :set isLastLinkUpTimeChanged true
    }
  }

  :if ($isLastLinkUpTimeChanged) do={

    # ----- Build message in the exact required format -----
    :local telegramMessage ($scriptVersion.": " . $pppInterfaceName . "\n" . \
                            "Total downs: " . $linkDownCount . "\n" . \
                            "Last DOWN: " . $lastLinkDownTime . "\n" . \
                            "Last UP:        " . $lastLinkUpTime)

    :set tgText $telegramMessage

    # URL encode message (spaces → %20, line breaks → %0A)
    :local plainText $telegramMessage
    :local encodedText ""
    :for i from=0 to=([:len $plainText]-1) do={
      :local ch [:pick $plainText $i ($i+1)]
      :if ($ch=" ") do={
        :set encodedText ($encodedText . "%20")
      } else={
        :if ($ch="\n") do={
          :set encodedText ($encodedText . "%0A")
        } else={
          :set encodedText ($encodedText . $ch)
        }
      }
    }

    :local url ("https://api.telegram.org/bot" . $telegramBotToken . "/sendMessage?chat_id=" . $telegramChatId . "&text=" . $encodedText . "&disable_web_page_preview=1")
    :do { 
      /tool fetch url=$url keep-result=no http-method=get 
      :log info ($scriptVersion.": UP - notified")

      # Store the last sent values (anti-duplicate) - ONLY on success
      :set frNotifiedUp $lastLinkUpTime
      :set frNotifiedDowns $linkDownCount
    } on-error={ 
      :log warning ($scriptVersion.": tg send failed - will retry next run") 
    }
  }

  # Store the last read value (compatibility with the original script)
  :set frPrevLastUp $lastLinkUpTime

  # Release mutex
  :set frBusy false

} on-error={
  :set frBusy false
  :log warning ($scriptVersion.": caught-error")
}

# ========= /FRv5.3-uptime-watch =========