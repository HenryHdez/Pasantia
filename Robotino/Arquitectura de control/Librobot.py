import math
import requests
import time
import json
import matplotlib.pyplot as plt
import random

# Parámetros de movimiento
vx_script = 0.1#0.145  # Velocidad lineal constante en el script (m/s)
omega_script = 0.1#0.1285  # Velocidad angular constante en el script (rad/s)
tolerancia_angular = 0.135  # Tolerancia para el ángulo en radianes (~5.7 grados)
tolerancia_distancia = 0.05  # Tolerancia para la distancia en metros (5 cm)
intervalo_envio = 0.235  # Intervalo en segundos (200 ms) para enviar comandos
delta_t = intervalo_envio * 0.3159 + intervalo_envio
# Variables globales para la posición y orientación iniciales
x_actual = 1.0
y_actual = 0.0
theta_actual = 0.0

def val_iniciales(x, y, t, vx, vt, ta, td):
    global x_actual, y_actual, theta_actual, vx_script, omega_script, tolerancia_angular, tolerancia_distancia
    vx_script=vx
    omega_script=vt
    tolerancia_angular=ta
    tolerancia_distancia=td
    x_actual = x
    y_actual = y
    theta_actual = t

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
def esquivar_obstaculo(ip, posiciones_robot, trayectoria_robot, robot_actual, orientacion_robot):
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
            actualizar_posicion_y_orientacion(robot_actual, orientacion_robot)
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
            actualizar_posicion_y_orientacion(robot_actual, orientacion_robot)
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
            actualizar_posicion_y_orientacion(robot_actual, orientacion_robot)
        time.sleep(intervalo_envio)
    enviar_comandos_movimiento(ip, 0, 0, 0)  # Detener giro

# Función para actualizar la trayectoria en la gráfica
def actualizar_trayectoria(trayectoria_robot, posiciones_robot):
    trayectorias_x = [pos[0] for pos in posiciones_robot]
    trayectorias_y = [pos[1] for pos in posiciones_robot]
    trayectoria_robot.set_data(trayectorias_x, trayectorias_y)
    plt.draw()
    plt.pause(0.1)

# Función para actualizar la posición y orientación del robot en la gráfica
def actualizar_posicion_y_orientacion(robot_actual, orientacion_robot):
    # Actualizar la posición del robot (punto verde)
    robot_actual.set_data([x_actual], [y_actual])

    # Actualizar la orientación del robot (flecha roja)
    longitud_flecha = 0.2
    orientacion_x = [x_actual, x_actual + longitud_flecha * math.cos(theta_actual)]
    orientacion_y = [y_actual, y_actual + longitud_flecha * math.sin(theta_actual)]
    orientacion_robot.set_data(orientacion_x, orientacion_y)

    plt.draw()
    plt.pause(0.1)

# Crear una lista de destinos con un número definido de puntos intermedios y tiempos de parada
def generar_destinos_con_intermedios(lista_destinos, tiempos_parada, num_intermedios):
    nuevos_destinos = []
    nuevos_tiempos_parada = []

    for i in range(len(lista_destinos) - 1):
        # Agregar destino original
        nuevos_destinos.append(lista_destinos[i])
        nuevos_tiempos_parada.append(tiempos_parada[i])

        # Calcular y agregar puntos intermedios
        destino_inicial = lista_destinos[i]
        destino_final = lista_destinos[i + 1]

        for j in range(1, num_intermedios + 1):
            # Calcular la posición del punto intermedio como interpolación lineal
            x_intermedio = destino_inicial[0] + (destino_final[0] - destino_inicial[0]) * j / (num_intermedios + 1)
            y_intermedio = destino_inicial[1] + (destino_final[1] - destino_inicial[1]) * j / (num_intermedios + 1)
            nuevos_destinos.append((x_intermedio, y_intermedio))
            nuevos_tiempos_parada.append(0)  # Sin parada en los puntos intermedios

    # Agregar el último destino y su tiempo de parada
    nuevos_destinos.append(lista_destinos[-1])
    nuevos_tiempos_parada.append(tiempos_parada[-1])

    return nuevos_destinos, nuevos_tiempos_parada

# Función principal de movimiento con esquiva de obstáculos mejorada
def mover_robot(ip, lista_destinos, tiempos_parada, Dimensiones="500x600+0+10", num_intermedios=1):
    # Variables iniciales del robot
    global x_actual, y_actual, theta_actual
    posiciones_robot = []

    plt.switch_backend('TkAgg')

    # Crear la figura con una altura menor
    fig, (ax_trayectoria, ax_sensores) = plt.subplots(2, 1, figsize=(5, 6))  # Reduce el segundo valor para menor altura de figura

    # Obtener el administrador de la ventana y ajustar su posición y tamaño
    manager = plt.get_current_fig_manager()
    manager.window.wm_geometry(Dimensiones)  # Ajusta "500x600" para controlar el tamaño total de la ventana

    # Configurar los límites y el título del gráfico
    ax_trayectoria.set_xlim(-0.5, 2)
    ax_trayectoria.set_ylim(-0.5, 2)
    ax_trayectoria.grid(True)
    ax_trayectoria.set_title(f"Trayectoria del Robot en IP: {ip}")

    # Dibujar los destinos principales y puntos intermedios
    destinos_x = [destino[0] for destino in lista_destinos]
    destinos_y = [destino[1] for destino in lista_destinos]
    ax_trayectoria.plot(destinos_x, destinos_y, 'ro', label="Destinos")

    for i in range(1, len(lista_destinos) - 1):
        if tiempos_parada[i] == 0:
            ax_trayectoria.plot(lista_destinos[i][0], lista_destinos[i][1], 'o', color='violet', label="Punto Intermedio")

    # Preparar elementos gráficos para la trayectoria y orientación del robot
    trayectoria_robot, = ax_trayectoria.plot([], [], 'b-', lw=2, label="Trayectoria Robot")
    robot_actual, = ax_trayectoria.plot([], [], 'go', label="Posición Robot")
    orientacion_robot, = ax_trayectoria.plot([], [], 'r-', lw=2, label="Orientación")

    # Configurar el gráfico de sensores sin crear nuevos ejes
    ax_sensores.set_ylim(0, 1)
    ax_sensores.set_title("Sensores de Proximidad")
    ax_sensores.set_xlabel("Sensor")
    ax_sensores.set_ylabel("Distancia")
    barras_sensores = ax_sensores.bar(range(9), [0]*9, color='c')

    # Lógica de movimiento del robot con esquiva de obstáculos
    for i, destino in enumerate(lista_destinos):
        print(f"Moviendo hacia el destino: {destino}")

        while True:
            posicion = leer_odometro(ip)
            sensores = proximidad_robot(ip)

            if posicion:
                x_odometro, y_odometro, theta_odometro, vx_odometro, omega_odometro = posicion
                angulo_objetivo = calcular_angulo_objetivo(x_actual, y_actual, destino)
                delta_angulo = (angulo_objetivo - theta_actual + math.pi) % (2 * math.pi) - math.pi
                distancia = calcular_distancia(x_actual, y_actual, destino)

                if sensores[0] < 0.12:
                    print("Obstáculo detectado! Realizando maniobra de esquiva.")
                    esquivar_obstaculo(ip, posiciones_robot, trayectoria_robot, robot_actual, orientacion_robot)
                    sensores = proximidad_robot(ip)
                    if sensores[0] >= 0.12:
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
                    
                    if i < len(tiempos_parada) and tiempos_parada[i] > 0:
                        time.sleep(tiempos_parada[i])  # Detener el robot por el tiempo especificado
                    break

                integrar_velocidades(vx_odometro, omega_odometro, delta_t)
                posiciones_robot.append([x_actual, y_actual])

            actualizar_trayectoria(trayectoria_robot, posiciones_robot)
            actualizar_posicion_y_orientacion(robot_actual, orientacion_robot)

            for j, barra in enumerate(barras_sensores):
                barra.set_height(sensores[j])

            #plt.draw()
            #plt.pause(0.05)



# Función principal
if __name__ == "__main__":
    ip_robot = "192.168.1.101"
    # Lista de destinos y tiempos de parada en segundos
    lista_destinos = [(1.0, 0.0), (1.0, 1.0), (0.0, 0.0), (0.0, 1.0), (1.5, 1.0), (0.0, 0.0)]
    tiempos_parada = [2, 3, 1, 2, 3, 1]  # Tiempo de parada en segundos en cada destino
    mover_robot(ip_robot, lista_destinos, tiempos_parada)
