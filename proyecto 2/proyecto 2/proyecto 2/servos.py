
 # servos.py
 # Created: 14/05/26
 # Author: Jose Méndez
 # Description: Archivo para configurar el adafruit al micro.
import sys
import time
import serial
import threading
from Adafruit_IO import MQTTClient
# =========================
# CONFIGURACIÓN ADAFRUIT IO
# =========================

ADAFRUIT_IO_USERNAME = "men24076"
ADAFRUIT_IO_KEY = "aio_FIdU72CWcUzFySBoJ7YMqTGYN5kH"

# =========================
# CONFIGURACIÓN SERIAL
# =========================

COM_PORT = "COM5"
BAUD_RATE = 9600

arduino = serial.Serial(COM_PORT, BAUD_RATE, timeout=1)
time.sleep(2) #esperamos 2 segundos para abrir el canal serial y evitar problemas de comunicación iniciales

# =========================
# FEEDS ADAFRUIT
# =========================
FEEDS_TX = {
    "servo1-tx": 1,
    "servo2-tx": 2,
    "servo3-tx": 3,
    "servo4-tx": 4
}

FEEDS_RX = {
    1: "servo1-rx",
    2: "servo2-rx",
    3: "servo3-rx",
    4: "servo4-rx"
}

PB_FEED = "PB-TX"

last_save_time = 0
SAVE_COOLDOWN = 1.5 #antirebote del botón de guardar (1.5 segundos)
next_save_state = 1


# =========================
# FUNCIONES AUXILIARES
# =========================

def limitar_angulo(valor): #recibe lo que venga del slider de adafruit
    try:
        angulo = int(float(valor)) #float por si viene con decimal
    except:
        return None

    if angulo < 0: #limita los angulos
        angulo = 0

    if angulo > 180:
        angulo = 180

    return angulo


def enviar_serial(comando): #mandamos información al micro a través de serial
    arduino.write((comando + "\n").encode())


def mostrar_accion(comando): #muestra en la terminal lo que se ha enviado al micro, para tener un feedback visual
    comando = comando.strip().upper()

    if comando == "M": #modo manual
        print("Modo manual activado")

    elif comando == "G": #guardar estado
        print("Guardando estado actual en EEPROM")

    elif comando in ["1", "2", "3", "4"]: #manda el estado en el que se guardo al apachar el boton
        print(f"Estado {comando} cargado desde EEPROM")

    elif comando.startswith("S"): #por si se quiere escribir el angulo directamente
        print(f"Comando enviado a servo: {comando}")

    else: #por si no entiende el comando 
        print(f"Comando enviado: {comando}")


# =========================
# CALLBACKS ADAFRUIT
# =========================

def connected(client): #cuando se conecta a adafruit io, se subscribe a los feeds de los sliders y el botón
    print("Conectado a Adafruit IO")

    for feed in FEEDS_TX:
        client.subscribe(feed)

    client.subscribe(PB_FEED)


def disconnected(client): #cuando se desconecta de adafruit io, muestra un mensaje y termina el programa
    print("Desconectado de Adafruit IO")
    sys.exit(1)


def message(client, feed_id, payload): #cuando llega un mensaje de adafruit io, dependiendo del feed_id hace una cosa u otra
    global last_save_time #evita que python cree variables nuevas

    # BOTÓN GUARDAR EEPROM

    if feed_id == PB_FEED: #si se apacho el boton entra aqui 
        global next_save_state

        payload_str = str(payload).strip().lower() #convierte el valor que manda el boton 

        if payload_str not in ["1", "g"]:
            return

        current_time = time.time() #tiempo actual 

        if current_time - last_save_time < SAVE_COOLDOWN:#evita a que tome muchos registros por 1.5s
            return

        last_save_time = current_time #actualiza el tiempo del último guardado

        comando = "G"
        enviar_serial(comando) #mandamos el comando G para guardar en el micro

        print(f"Estado {next_save_state} guardado en EEPROM")#imprime el estado guardado

        next_save_state += 1 #aumenta el contador y lo limita a 4

        if next_save_state > 4:
            next_save_state = 1

        return

    # =========================
    # SLIDERS DE SERVOS
    # =========================

    if feed_id not in FEEDS_TX:
        return

    servo = FEEDS_TX[feed_id] #busca el servo que se toco en adafruit
    angulo = limitar_angulo(payload) #convierte el valor del slider

    if angulo is None:
        return

    comando = f"S{servo}:{angulo}"

    enviar_serial(comando) #manda el comando reconocible al micro para mover el servo

    rx_feed = FEEDS_RX[servo]
    client.publish(rx_feed, angulo) #pone el angulo en adafruit tmb 

    print(f"Servo {servo} colocado en {angulo}°") #muestra el servo que se movio en la terminal
    print(comando)


# =========================
# CONTROL DESDE TERMINAL
# =========================

def terminal_input(): #escribimos comandos en python 
    while True:
        cmd = input("")

        cmd = cmd.strip()

        if cmd != "":
            enviar_serial(cmd) #lo manda al micro por serial
            mostrar_accion(cmd)


# =========================
# CLIENTE MQTT
# =========================

client = MQTTClient(ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)

client.on_connect = connected
client.on_disconnect = disconnected
client.on_message = message

client.connect()
client.loop_background()

thread = threading.Thread(target=terminal_input, daemon=True)
thread.start()


# =========================
# LOOP PRINCIPAL
# =========================

while True:
    time.sleep(0.1)