# ========= FRv4.0d-uptime-watch (ROS 7.20.x) =========
# Trigger: change of last-link-up-time on the PPPoE interface (with debounce).
# Telegram message exactly as in the sample:
# <ver>: <iface>
# Total downs: <downs>
# Last DOWN: <lastDown>
# Last UP:        <lastUp>

:local ver "FRv4.0d"
:local ppp "Telekom-pppoe-out"

# Telegram (minimal URL encoding: spaces and \n)
:local tgToken "xxx"
:local tgChat  "xxx"

# Globals
:global frPrevLastUp
:global tgText

# Anti-duplicates (debounce + mutex)
:global frCandUp
:global frCandSeen
:global frNotifiedUp
:global frBusy

:do {

  # Mutex to prevent concurrent runs
  :if ([:typeof $frBusy] != "nil" && $frBusy=true) do={ :return }
  :set frBusy true

  # Interface identifier
  :local ifId [/interface find where name=$ppp]
  :if ([:len $ifId]=0) do={ :set frBusy false ; :log warning ($ver.": iface not found: ".$ppp) ; :return }

  # Current values (with protection)
  :local lastUp ""    ; :do { :set lastUp    [/interface get $ifId last-link-up-time]   } on-error={ :set lastUp "" }
  :local lastDown ""  ; :do { :set lastDown  [/interface get $ifId last-link-down-time] } on-error={ :set lastDown "" }
  :local downs ""     ; :do { :set downs     [/interface get $ifId link-downs]          } on-error={ :set downs "" }

  # Debounce initialization
  :if ([:typeof $frCandUp] = "nil" || [:len [:tostr $frCandUp]] = 0) do={ :set frCandUp "" }
  :if ([:typeof $frCandSeen] = "nil" || [:len [:tostr $frCandSeen]] = 0) do={ :set frCandSeen 0 }
  :if ([:typeof $frNotifiedUp] = "nil") do={ :set frNotifiedUp "" }

  # Debounce last-link-up-time (2 identical reads in a row)
  :if ([:len $lastUp] > 0) do={
    :if ($frCandUp = $lastUp) do={
      :set frCandSeen ($frCandSeen + 1)
    } else={
      :set frCandUp $lastUp
      :set frCandSeen 1
    }
  } else={
    :set frCandSeen 0
  }

  # Detect a change (and the first run). Do not send until lastUp is stable twice.
  :local changed false
  :if ([:len $lastUp] > 0) do={
    :if ([:len [:tostr $frNotifiedUp]] = 0) do={
      :if ([:tonum $frCandSeen] >= 2) do={ :set changed true }
    } else={
      :if ($frNotifiedUp != $lastUp) do={
        :if ([:tonum $frCandSeen] >= 2) do={ :set changed true }
      }
    }
  }

  :if ($changed) do={

    # Message in the exact format
    :local msg ($ver.": " . $ppp . "\n" . \
                "Total downs: " . $downs . "\n" . \
                "Last DOWN: " . $lastDown . "\n" . \
                "Last UP:        " . $lastUp)

    :set tgText $msg

    # Mini-encoder (spaces and line breaks)
    :local s $msg ; :local out ""
    :for i from=0 to=([:len $s]-1) do={
      :local ch [:pick $s $i ($i+1)]
      :if ($ch=" ") do={ :set out ($out . "%20") } else={
        :if ($ch="\n") do={ :set out ($out . "%0A") } else={ :set out ($out . $ch) }
      }
    }

    :local url ("https://api.telegram.org/bot" . $tgToken . "/sendMessage?chat_id=" . $tgChat . "&text=" . $out . "&disable_web_page_preview=1")
    :do { /tool fetch url=$url keep-result=no http-method=get } on-error={ :log warning ($ver.": tg send failed") }
    :log info ($ver.": UP — notified")

    # Store the last notified value (anti-duplicate)
    :set frNotifiedUp $lastUp
  }

  # Store the last value (as in the source)
  :set frPrevLastUp $lastUp

  # Release mutex
  :set frBusy false

} on-error={
  :set frBusy false
  :log warning ($ver.": caught-error")
}

# ========= /FRv4.0d-uptime-watch =========