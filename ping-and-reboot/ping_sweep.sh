#!/usr/bin/env bash


#############################
#         Farben
#############################
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[93m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

#############################
#    Datei-Definitionen
#############################
DATA_DIR="data"                             # Unterordner für unsere Dateien
NETWORKS_FILE="${DATA_DIR}/networks.txt"    # Hier stehen die Netzwerke (CIDR) zeilenweise.
ALIVE_FILE="${DATA_DIR}/alive_hosts.txt"    # Hier werden alle erreichbaren IPs gespeichert.

#############################
#     Funktionen
#############################

# Titelzeile (ASCII-Banner o.Ä.)
function print_banner() {
  echo -e "${CYAN}${BOLD}"
  echo "=============================================================="
  echo "   P I N G - S W E E P   S C R I P T"
  echo "=============================================================="
  echo -e "${RESET}"
}

# Check auf fping
function check_fping() {
  if ! command -v fping &> /dev/null
  then
      echo -e "${RED}[FEHLER]${RESET} Das Programm 'fping' ist nicht installiert!"
      echo "Bitte installiere fping (z.B. sudo apt-get install fping) und versuche es erneut."
      exit 1
  fi
}

# Kurze Hilfe-/Usage-Anzeige
function usage() {
  echo "Usage: $0 [OPTION]"
  echo "  -n, --networks  Dateiname mit den CIDR-Netzwerken (Standard: $NETWORKS_FILE)"
  echo "  -o, --output    Dateiname für die erreichbaren Hosts (Standard: $ALIVE_FILE)"
  echo "  -h, --help      Hilfe anzeigen"
  exit 0
}

#############################
#   Argumente parsen
#############################
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -n|--networks)
      NETWORKS_FILE="$2"
      shift
      ;;
    -o|--output)
      ALIVE_FILE="$2"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo -e "${RED}[FEHLER]${RESET} Unbekannte Option: $1"
      usage
      ;;
  esac
  shift
done

#############################
# Hauptprogramm
#############################

print_banner
check_fping

# Prüfen, ob das data-Verzeichnis existiert, ggf. erstellen
if [[ ! -d "$DATA_DIR" ]]; then
  mkdir -p "$DATA_DIR"
  echo -e "${YELLOW}[INFO]${RESET} Ordner '${BOLD}$DATA_DIR${RESET}' wurde erstellt."
fi

# Prüfen, ob die Datei mit den Netzwerken existiert
if [[ ! -f "$NETWORKS_FILE" ]]; then
  echo -e "${RED}[FEHLER]${RESET} Datei ${BOLD}$NETWORKS_FILE${RESET} nicht gefunden!"
  echo "Bitte sicherstellen, dass die Datei existiert und erneut ausführen."
  exit 1
fi

# Alive-Hosts-Datei leeren
> "$ALIVE_FILE"
echo -e "${GREEN}[INFO]${RESET} Alte Einträge in ${BOLD}$ALIVE_FILE${RESET} wurden gelöscht."

# Netzwerke einlesen und abarbeiten
echo -e "${GREEN}[INFO]${RESET} Beginne mit dem Ping-Sweep..."
echo

while read -r NETWORK
do
  # Leere Zeilen oder Zeilen mit Kommentar (#) überspringen
  if [[ -z "$NETWORK" || "$NETWORK" =~ ^# ]]; then
    continue
  fi

  echo -e "${YELLOW}[STARTE]${RESET} Bearbeite Netzwerk: ${BOLD}$NETWORK${RESET}"

  # fping -a -g pingt alle IP-Adressen im Bereich an und gibt nur erreichbare aus
  # 2>/dev/null leitet Fehlermeldungen (z.B. bei nicht erreichbaren IPs) ab
  fping -a -g "$NETWORK" 2>/dev/null >> "$ALIVE_FILE"

  echo -e "${GREEN}[FERTIG]${RESET} Netzwerk ${BOLD}$NETWORK${RESET} abgearbeitet."
  echo
done < "$NETWORKS_FILE"

echo -e "${CYAN}[INFO]${RESET} Alle IPs, die auf ICMP geantwortet haben, stehen in ${BOLD}$ALIVE_FILE${RESET}."
echo -e "${CYAN}[ENDE]${RESET} Skript abgeschlossen."

