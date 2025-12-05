# ========= FRv4.0d-uptime-watch (ROS 7.20.x) =========
# Триггер: смена last-link-up-time у PPPoE-интерфейса (с дебаунсом).
# Сообщение в Telegram строго как в образце:
# <ver>: <iface>
# Total downs: <downs>
# Last DOWN: <lastDown>
# Last UP:        <lastUp>

:local ver "FRv4.0d"
:local ppp "Telekom-pppoe-out"

# Telegram (минимальное URL-кодирование: пробелы и \n)
:local tgToken "xxx"
:local tgChat  "xxx"

# Глобалы
:global frPrevLastUp
:global tgText

# Антидубли (дебаунс + мьютекс)
:global frCandUp
:global frCandSeen
:global frNotifiedUp
:global frBusy

:do {

  # Мьютекс от параллельных запусков
  :if ([:typeof $frBusy] != "nil" && $frBusy=true) do={ :return }
  :set frBusy true

  # Идентификатор интерфейса
  :local ifId [/interface find where name=$ppp]
  :if ([:len $ifId]=0) do={ :set frBusy false ; :log warning ($ver.": iface not found: ".$ppp) ; :return }

  # Текущие значения (с защитой)
  :local lastUp ""    ; :do { :set lastUp    [/interface get $ifId last-link-up-time]   } on-error={ :set lastUp "" }
  :local lastDown ""  ; :do { :set lastDown  [/interface get $ifId last-link-down-time] } on-error={ :set lastDown "" }
  :local downs ""     ; :do { :set downs     [/interface get $ifId link-downs]          } on-error={ :set downs "" }

  # Инициализация антидребезга
  :if ([:typeof $frCandUp] = "nil" || [:len [:tostr $frCandUp]] = 0) do={ :set frCandUp "" }
  :if ([:typeof $frCandSeen] = "nil" || [:len [:tostr $frCandSeen]] = 0) do={ :set frCandSeen 0 }
  :if ([:typeof $frNotifiedUp] = "nil") do={ :set frNotifiedUp "" }

  # Дебаунс last-link-up-time (2 одинаковых чтения подряд)
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

  # Определяем изменение (и первый запуск). Не шлём, пока lastUp не стабилен два раза.
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

    # Сообщение в точном формате
    :local msg ($ver.": " . $ppp . "\n" . \
                "Total downs: " . $downs . "\n" . \
                "Last DOWN: " . $lastDown . "\n" . \
                "Last UP:        " . $lastUp)

    :set tgText $msg

    # Мини-энкодер (пробелы и переносы строк)
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

    # Запоминаем последнее уведомлённое значение (антидубли)
    :set frNotifiedUp $lastUp
  }

  # Запоминаем последнее значение (как в исходнике)
  :set frPrevLastUp $lastUp

  # Снять мьютекс
  :set frBusy false

} on-error={
  :set frBusy false
  :log warning ($ver.": caught-error")
}

# ========= /FRv4.0d-uptime-watch =========