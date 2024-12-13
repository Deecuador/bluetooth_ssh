#!/bin/bash

DEVICE_MAC="C4:30:18:43:E9:1C"
MUSIC_DIR="$(pwd)/musica"

# Verificar dependencias
for cmd in bluetoothctl zenity cvlc; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: $cmd no está instalado. Por favor, instálalo antes de ejecutar este script."
        exit 1
    fi
done

# Asegurar que el servicio Bluetooth esté activo
if ! systemctl is-active --quiet bluetooth; then
    echo "Iniciando el servicio Bluetooth..."
    systemctl start bluetooth
fi

# Conectar al dispositivo Bluetooth
if bluetoothctl info "$DEVICE_MAC" | grep -q "Connected: yes"; then
    echo "Ya estás conectado al dispositivo."
else
    echo "Conectando al dispositivo Bluetooth..."
    bluetoothctl connect "$DEVICE_MAC" || { echo "Error al conectar al dispositivo."; exit 1; }
fi

# Validar el directorio de música
if [ ! -d "$MUSIC_DIR" ]; then
    echo "Error: El directorio $MUSIC_DIR no existe."
    exit 1
fi

MUSIC_FILES=("$MUSIC_DIR"/*.mp3)
if [ ${#MUSIC_FILES[@]} -eq 0 ]; then
    echo "No se encontraron archivos .mp3 en $MUSIC_DIR."
    exit 1
fi

# Mostrar la pregunta solo antes de la primera canción
zenity --question --title="Reproducción de Música" \
    --text="Se encontraron ${#MUSIC_FILES[@]} canciones en la carpeta.\n¿Deseas iniciar la reproducción?" \
    --ok-label="Sí" --cancel-label="No"

if [ $? -eq 1 ]; then
    echo "Has cancelado la reproducción."
    exit 0
fi

# Reproducción de música
for ((i=0; i<${#MUSIC_FILES[@]}; i++)); do
    current_song=$(basename "${MUSIC_FILES[$i]}")
    echo "Reproduciendo: $current_song"

    if ((i + 1 < ${#MUSIC_FILES[@]})); then
        next_file=$(basename "${MUSIC_FILES[$((i + 1))]}") || "No hay más canciones."
    else
        next_file="No hay más canciones."
    fi

    # Reproducción automática de canciones
    echo "Reproduciendo automáticamente: $current_song"
    cvlc "${MUSIC_FILES[$i]}" --play-and-exit &
    vlc_pid=$!  # Guardar el PID del proceso VLC
    wait $vlc_pid  # Esperar a que termine la reproducción
done

echo "Reproducción completada. ¡Disfruta!"
