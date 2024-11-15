import math
import requests
import time
import json
import matplotlib.pyplot as plt
import random

# Parámetros iniciales para la simulación
x_actual = 0.0  # Posición inicial en el eje x
y_actual = 0.0  # Posición inicial en el eje y
theta_actual = 0.0  # Orientación inicial del robot en radianes

# Parámetros de movimiento
vx_script = 0.155  # Velocidad lineal constante en el script (m/s)
omega_script = 0.125  # Velocidad angular constante en el script (rad/s)
tolerancia_angular = 0.105  # Tolerancia para el ángulo en radianes (~5.7 grados)
tolerancia_distancia = 0.04  # Tolerancia para la distancia en metros (5 cm)
intervalo_envio = 0.185  # Intervalo en segundos (200 ms) para enviar comandos
delta_t = intervalo_envio * 0.3355 + intervalo_envio

# Función para enviar los comandos de movimiento al robot
def enviar_comandos_movimiento(ip, vx, vy, omega):
    url = f'http://{ip}/data/omnidrive'
    vel_vector = [vx, vy, omega]
    datos_json = json.dumps(vel_vector)
    try:
        headers = {'Content-Type': 'application/json'}
        response = requests.post(url, data=datos_json, headers=headers)
        if response.status_code != 200:
            print(f"Error: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f'Error al enviar comandos de movimiento: {e}')

# Función para leer los datos del odómetro
def leer_odometro(ip):
    url_odometry = f'http://{ip}/data/odometry'
    try:
        response = requests.get(url_odometry)
        if response.status_code == 200:
            odometro_datos = response.json()
            return odometro_datos[0], odometro_datos[1], odometro_datos[2], odometro_datos[3], odometro_datos[5]
        else:
            print(f"Error al leer el odómetro: {response.status_code}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"Error al conectarse al odómetro: {e}")
        return None

# Función para leer los sensores de proximidad del robot
def proximidad_robot(ip):
    url = f'http://{ip}/data/distancesensorarray'
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()
        else:
            print(f'Error al leer sensores: {response.status_code} - {response.text}')
            return [0] * 9  # Devuelve una lista con ceros si hay error
    except requests.exceptions.RequestException as e:
        print(f'Error al leer sensores: {e}')
        return [0] * 9  # Devuelve una lista con ceros en caso de excepción


# Función para integrar las velocidades medidas desde el odómetro
def integrar_velocidades(vx_odometro, omega_odometro, delta_t):
    global x_actual, y_actual, theta_actual

    # Actualizar la posición usando las velocidades medidas
    x_actual += vx_odometro * delta_t * math.cos(theta_actual)
    y_actual += vx_odometro * delta_t * math.sin(theta_actual)

    # Actualizar la orientación (theta) usando la velocidad angular medida
    theta_actual += omega_odometro * delta_t
    theta_actual = theta_actual % (2 * math.pi)  # Asegurar que esté entre 0 y 2π

# Función para calcular el ángulo hacia el destino
def calcular_angulo_objetivo(x_actual, y_actual, destino):
    delta_x = destino[0] - x_actual
    delta_y = destino[1] - y_actual
    return math.atan2(delta_y, delta_x)  # Ángulo en radianes

# Función para calcular la distancia euclidiana entre el robot y el destino
def calcular_distancia(x_actual, y_actual, destino):
    return math.sqrt((destino[0] - x_actual) ** 2 + (destino[1] - y_actual) ** 2)

# Función para esquivar obstáculo, ejecutando comandos cada 200 ms y actualizando la trayectoria
def esquivar_obstaculo(ip, posiciones_robot, trayectoria_robot):
    direccion_giro = random.choice([-1, 1])  # -1 para izquierda, 1 para derecha

    # Girar 90 grados en la dirección elegida
    tiempo_giro = 10
    start_time = time.time()
    while time.time() - start_time < tiempo_giro:
        enviar_comandos_movimiento(ip, 0, 0, direccion_giro * omega_script)
        posicion = leer_odometro(ip)
        if posicion:
            vx_odometro, omega_odometro = posicion[3], posicion[4]
            integrar_velocidades(vx_odometro, omega_odometro, delta_t)
            posiciones_robot.append([x_actual, y_actual])
            actualizar_trayectoria(trayectoria_robot, posiciones_robot)
        time.sleep(intervalo_envio)
    enviar_comandos_movimiento(ip, 0, 0, 0)  # Detener giro

    # Avanzar 20 cm en la dirección girada
    tiempo_avance = 3
    start_time = time.time()
    while time.time() - start_time < tiempo_avance:
        enviar_comandos_movimiento(ip, vx_script, 0, 0)
        posicion = leer_odometro(ip)
        if posicion:
            vx_odometro, omega_odometro = posicion[3], posicion[4]
            integrar_velocidades(vx_odometro, omega_odometro, delta_t)
            posiciones_robot.append([x_actual, y_actual])
            actualizar_trayectoria(trayectoria_robot, posiciones_robot)
        time.sleep(intervalo_envio)
    enviar_comandos_movimiento(ip, 0, 0, 0)  # Detener avance

    # Girar 90 grados de vuelta para retomar la ruta original
    start_time = time.time()
    while time.time() - start_time < tiempo_giro:
        enviar_comandos_movimiento(ip, 0, 0, -direccion_giro * omega_script)
        posicion = leer_odometro(ip)
        if posicion:
            vx_odometro, omega_odometro = posicion[3], posicion[4]
            integrar_velocidades(vx_odometro, omega_odometro, delta_t)
            posiciones_robot.append([x_actual, y_actual])
            actualizar_trayectoria(trayectoria_robot, posiciones_robot)
        time.sleep(intervalo_envio)
    enviar_comandos_movimiento(ip, 0, 0, 0)  # Detener giro

# Función para actualizar la trayectoria en la gráfica
def actualizar_trayectoria(trayectoria_robot, posiciones_robot):
    trayectorias_x = [pos[0] for pos in posiciones_robot]
    trayectorias_y = [pos[1] for pos in posiciones_robot]
    trayectoria_robot.set_data(trayectorias_x, trayectorias_y)
    plt.draw()
    plt.pause(0.1)

# Modificación en la función `mover_robot` para pasar `trayectoria_robot`
def mover_robot(ip, lista_destinos):
    global x_actual, y_actual, theta_actual
    posiciones_robot = []

    plt.ion()
    fig, (ax_trayectoria, ax_sensores) = plt.subplots(1, 2, figsize=(10, 5))
    ax_trayectoria.set_xlim(-1, 3)
    ax_trayectoria.set_ylim(-1, 3)
    ax_trayectoria.grid(True)

    destinos_x = [destino[0] for destino in lista_destinos]
    destinos_y = [destino[1] for destino in lista_destinos]
    ax_trayectoria.plot(destinos_x, destinos_y, 'ro', label="Destinos")

    trayectoria_robot, = ax_trayectoria.plot([], [], 'b-', lw=2, label="Trayectoria Robot")
    robot_actual, = ax_trayectoria.plot([], [], 'go', label="Posición Robot")
    orientacion_robot, = ax_trayectoria.plot([], [], 'r-', lw=2, label="Orientación")

    ax_sensores.set_ylim(0, 1)
    ax_sensores.set_title("Sensores de Proximidad")
    ax_sensores.set_xlabel("Sensor")
    ax_sensores.set_ylabel("Distancia")
    barras_sensores = ax_sensores.bar(range(9), [0]*9, color='c')

    for destino in lista_destinos:
        print(f"Moviendo hacia el destino: {destino}")
        
        while True:
            posicion = leer_odometro(ip)
            sensores = proximidad_robot(ip)

            if posicion:
                x_odometro, y_odometro, theta_odometro, vx_odometro, omega_odometro = posicion
                angulo_objetivo = calcular_angulo_objetivo(x_actual, y_actual, destino)
                delta_angulo = (angulo_objetivo - theta_actual + math.pi) % (2 * math.pi) - math.pi
                distancia = calcular_distancia(x_actual, y_actual, destino)

                if sensores[0] < 0.12:  # Si el sensor 0 detecta un obstáculo cercano
                    print("Obstáculo detectado! Realizando maniobra de esquiva.")
                    esquivar_obstaculo(ip, posiciones_robot, trayectoria_robot)

                    # Verificar si hay obstáculo después de la maniobra
                    sensores = proximidad_robot(ip)
                    if sensores[0] >= 0.12:  # No hay obstáculo, retomar ruta
                        continue
                    else:
                        print("Obstáculo aún presente, ajustando ruta.")
                        ax_trayectoria.plot(x_actual, y_actual, 'rx', label="Obstáculo")
                
                elif abs(delta_angulo) > tolerancia_angular:
                    omega = omega_script if delta_angulo > 0 else -omega_script
                    enviar_comandos_movimiento(ip, 0, 0, omega)
                elif distancia > tolerancia_distancia:
                    enviar_comandos_movimiento(ip, vx_script, 0, 0)
                else:
                    print(f"Llegó al destino: {destino}")
                    enviar_comandos_movimiento(ip, 0, 0, 0)
                    break

                integrar_velocidades(vx_odometro, omega_odometro, delta_t)
                posiciones_robot.append([x_actual, y_actual])

            actualizar_trayectoria(trayectoria_robot, posiciones_robot)

            robot_actual.set_data([x_actual], [y_actual])

            longitud_flecha = 0.2
            orientacion_x = [x_actual, x_actual + longitud_flecha * math.cos(theta_actual)]
            orientacion_y = [y_actual, y_actual + longitud_flecha * math.sin(theta_actual)]
            orientacion_robot.set_data(orientacion_x, orientacion_y)

            # Actualizar la gráfica de sensores
            for i, barra in enumerate(barras_sensores):
                barra.set_height(sensores[i])

            plt.draw()
            plt.pause(0.1)

        time.sleep(1)

    plt.ioff()

# Función principal
if __name__ == "__main__":
    ip_robot = "192.168.1.101"
    lista_destinos = [(0.0, 2.0), (0.0, 0.0), (0.0, 2.0), (0.0, 0.0)]
    mover_robot(ip_robot, lista_destinos)
