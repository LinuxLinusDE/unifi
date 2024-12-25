#!/usr/bin/env bash

#################################################################
# Farb-Definitionen (ANSI/VT100)
#################################################################
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_RED="\033[1;31m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_BLUE="\033[1;34m"
C_MAGENTA="\033[1;35m"
C_CYAN="\033[1;36m"

#################################################################
# Hilfsfunktionen für gefärbte Ausgaben
#################################################################
function info() {
  echo -e "${C_BLUE}[INFO]${C_RESET} $*"
}
function warn() {
  echo -e "${C_YELLOW}[WARNUNG]${C_RESET} $*"
}
function error() {
  echo -e "${C_RED}[FEHLER]${C_RESET} $*"
}
function sshOutput() {
  echo -e "${C_MAGENTA}[SSH-AUSGABE]${C_RESET} $*"
}

#################################################################
# Konfigurationsvariablen
#################################################################
HOSTLIST="data/alive_hosts.txt"       # Pfad zur Hostliste
SSH_USER="sit"                       # SSH-Benutzername
REBOOT_CMD="reboot"                  # Auszuführender Befehl (z.B. "sudo /usr/sbin/reboot")
WAIT_BETWEEN_HOSTS=200               # Zeit (Sekunden) zwischen Hosts (NUR bei Erfolg)
CONNECT_TIMEOUT=10                   # SSH-Verbindungs-Timeout (nur Verbindungsaufbau)
SERVER_ALIVE_INTERVAL=2              # Keep-Alive-Interval (Sekunden)
SERVER_ALIVE_COUNTMAX=5              # Anzahl fehlender Antworten bis Abbruch
#################################################################

echo -e "${C_CYAN}=========================================================${C_RESET}"
info "Skript gestartet"
info "Hostliste:               $HOSTLIST"
info "SSH-Benutzer:            $SSH_USER"
info "Auszuführender Befehl:   $REBOOT_CMD"
info "Zeit zwischen Hosts:     $WAIT_BETWEEN_HOSTS Sekunden (nur bei erfolgreicher Verbindung)"
info "SSH-Timeout (Connect):   $CONNECT_TIMEOUT Sekunden"
info "ServerAliveInterval:     $SERVER_ALIVE_INTERVAL Sekunden"
info "ServerAliveCountMax:     $SERVER_ALIVE_COUNTMAX"
echo -e "${C_CYAN}=========================================================${C_RESET}"

# Prüfen, ob die Hostliste existiert
if [ ! -f "$HOSTLIST" ]; then
  error "Hostliste '$HOSTLIST' wurde nicht gefunden!"
  exit 1
fi

# Hostliste auf Dateideskriptor 3 öffnen
exec 3< "$HOSTLIST"

# Zeilenweises Einlesen der IP-Liste von FD 3
while IFS= read -u 3 -r ip; do
  
  # Leerzeilen oder Kommentarzeilen überspringen
  if [[ -z "$ip" ]] || [[ "$ip" =~ ^# ]]; then
    continue
  fi

  # Gateways erkennen (IPs, die auf '.1' enden) und überspringen
  if [[ "$ip" =~ \.1$ ]]; then
    info "Überspringe Gateway: $ip"
    continue
  fi

  echo -e "${C_CYAN}---------------------------------------------------------${C_RESET}"
  info "Verarbeite Host: $ip"
  info "Versuche SSH-Verbindung aufzubauen..."

  # SSH-Befehl ausführen
  ssh_output=$(
    ssh \
      -o StrictHostKeyChecking=no \
      -o PasswordAuthentication=no \
      -o ConnectTimeout="$CONNECT_TIMEOUT" \
      -o ServerAliveInterval="$SERVER_ALIVE_INTERVAL" \
      -o ServerAliveCountMax="$SERVER_ALIVE_COUNTMAX" \
      "$SSH_USER"@"$ip" \
      "echo '[HOST $ip] Starte Befehl...'; $REBOOT_CMD; sleep 1; exit" \
      2>&1
  )

  # Exit-Code prüfen
  ret_code=$?
  if [ $ret_code -ne 0 ]; then
    warn "Fehler beim Verbinden zu Host $ip (Exit-Code: $ret_code)."
    sshOutput "$ssh_output"
    warn "Keine Wartezeit, weiter mit dem nächsten Host..."
    continue
  else
    info "Host $ip: Befehl '$REBOOT_CMD' abgesetzt."
    sshOutput "$ssh_output"
  fi

  # NUR bei erfolgreicher Verbindung: Countdown
  info "Warte nun $WAIT_BETWEEN_HOSTS Sekunden, bevor der nächste Host angesprochen wird..."
  for (( i="$WAIT_BETWEEN_HOSTS"; i>0; i-- )); do
    printf "\r${C_GREEN}Noch %02d Sekunden...${C_RESET}" "$i"
    sleep 1
  done
  printf "\n"

done

# Dateideskriptor schließen
exec 3<&-

echo -e "${C_CYAN}---------------------------------------------------------${C_RESET}"
info "Skript beendet."
echo -e "${C_CYAN}=========================================================${C_RESET}"

