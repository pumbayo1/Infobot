#!/bin/bash

# Sprawdź, czy skrypt jest uruchamiany z uprawnieniami administratora
if [[ $EUID -ne 0 ]]; then
   echo "Ten skrypt musi być uruchomiony jako root" 
   exit 1
fi

echo "Instalacja wymagań..."

# Instalacja potrzebnych pakietów
apt update
apt install -y curl bc sysstat

# Zbieranie danych od użytkownika
read -p "Podaj token bota Telegram: " TOKEN
read -p "Podaj chat ID: " CHAT_ID
read -p "Podaj nazwę serwera: " SERVER

# Tworzenie skryptu monitorującego
cat <<EOL > monitor.sh
#!/bin/bash

# Ustawienia
TOKEN="$TOKEN"
CHAT_ID="$CHAT_ID"
SERVER="$SERVER"
THRESHOLD=5
COUNT=0

while true; do
    # Sprawdź zużycie CPU
    CPU_USAGE=\$(mpstat 1 1 | awk '/Average/ {print 100 - \$12}')

    # Sprawdź, czy zużycie jest w przedziale 0-5%
    if (( \$(echo "\$CPU_USAGE < \$THRESHOLD" | bc -l) )); then
        COUNT=\$((COUNT + 1))
    else
        COUNT=0
    fi

    # Jeśli zużycie jest poniżej 5% przez minutę (60 sekund)
    if [ \$COUNT -ge 60 ]; then
        MESSAGE="Server \$SERVER nie pracuje! Zużycie CPU: \$CPU_USAGE%"
        curl -s -X POST "https://api.telegram.org/bot\$TOKEN/sendMessage" -d "chat_id=\$CHAT_ID&text=\$MESSAGE"
        COUNT=0  # Resetuj licznik po wysłaniu powiadomienia
    fi

    sleep 1  # Sprawdzaj co sekundę
done
EOL

# Nadaj uprawnienia do skryptu
chmod +x monitor.sh

echo "Skrypt monitorujący został utworzony jako monitor.sh"
echo "Możesz uruchomić go za pomocą: ./monitor.sh &"
echo "Aby skrypt działał po wylogowaniu, użyj 'nohup ./monitor.sh &'"
