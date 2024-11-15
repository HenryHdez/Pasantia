import math
import requests
import time
import json
import matplotlib.pyplot as plt

# Parámetros iniciales para la simulación
x_actual = 0.0  # Posición inicial en el eje x
y_actual = 0.0  # Posición inicial en el eje y
theta_actual = 0.0  # Orientación inicial del robot en radianes

# Parámetros de movimiento
vx_script = 0.2  # Velocidad lineal constante en el script (m/s)
omega_script = 0.2  # Velocidad angular constante en el script (rad/s)
tolerancia_angular = 0.1  # Tolerancia para el ángulo en radianes (~5.7 grados)
tolerancia_distancia = 0.05  # Tolerancia para la distancia en metros (5 cm)
delta_t = 0.12  # Intervalo de tiempo (en segundos) para la integración de velocidades

# Función para enviar los comandos de movimiento al robot
def enviar_comandos_movimiento(ip, vx, vy, omega):
    url = f'http://{ip}/data/omnidrive'
    vel_vector = [vx, vy, omega]  # Enviar velocidades en m/s y rad/s
    datos_json = json.dumps(vel_vector)
    try:
        headers = {'Content-Type': 'application/json'}
        response = requests.post(url, data=datos_json, headers=headers)
        if response.status_code != 200:
            print(f"Error: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f'Error al enviar comandos de movimiento: {e}')

# Función para leer los datos del odómetro (posiciones y velocidades medidas)
def leer_odometro(ip):
    url_odometry = f'http://{ip}/data/odometry'
    try:
        response = requests.get(url_odometry)
        if response.status_code == 200:
            odometro_datos = response.json()  # [x, y, rot, vx, vy, omega, seq]
            return odometro_datos[0], odometro_datos[1], odometro_datos[2], odometro_datos[3], odometro_datos[5]  # Retorna x, y, theta, vx, omega
        else:
            print(f"Error al leer el odómetro: {response.status_code}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"Error al conectarse al odómetro: {e}")
        return None

# Función para calcular la distancia euclidiana entre el robot y el destino
def calcular_distancia(x_actual, y_actual, destino):
    return math.sqrt((destino[0] - x_actual)**2 + (destino[1] - y_actual)**2)

# Función para calcular el ángulo hacia el destino
def calcular_angulo_objetivo(x_actual, y_actual, destino):
    delta_x = destino[0] - x_actual
    delta_y = destino[1] - y_actual
    return math.atan2(delta_y, delta_x)  # Ángulo en radianes

# Función para integrar las velocidades medidas desde el odómetro
def integrar_velocidades(vx_odometro, omega_odometro, delta_t):
    global x_actual, y_actual, theta_actual

    # Actualizar la posición usando las velocidades medidas
    x_actual += vx_odometro * delta_t * math.cos(theta_actual)
    y_actual += vx_odometro * delta_t * math.sin(theta_actual)

    # Actualizar la orientación (theta) usando la velocidad angular medida
    theta_actual += omega_odometro * delta_t
    theta_actual = theta_actual % (2 * math.pi)  # Asegurar que esté entre 0 y 2π

# Función para mover el robot hacia el destino siguiendo la distancia euclidiana
def mover_robot(ip, lista_destinos):
    global x_actual, y_actual, theta_actual

    # Inicializar lista para almacenar las posiciones del robot
    posiciones_robot = []

    # Configurar el gráfico
    plt.ion()  # Modo interactivo
    fig, ax = plt.subplots()
    ax.set_xlim(-1, 3)  # Ajustar límites del gráfico en metros
    ax.set_ylim(-1, 3)
    ax.grid(True)

    # Graficar los destinos
    destinos_x = [destino[0] for destino in lista_destinos]
    destinos_y = [destino[1] for destino in lista_destinos]
    ax.plot(destinos_x, destinos_y, 'ro', label="Destinos")  # Graficar destinos como puntos rojos

    # Linea para la trayectoria del robot
    trayectoria_robot, = ax.plot([], [], 'b-', lw=2, label="Trayectoria Robot")
    robot_actual, = ax.plot([], [], 'go', label="Posición Robot")
    
    # Indicador de orientación del robot (flecha)
    orientacion_robot, = ax.plot([], [], 'r-', lw=2, label="Orientación")

    for destino in lista_destinos:
        print(f"Moviendo hacia el destino: {destino}")
        
        while True:
            # Leer la velocidad lineal y angular medidas desde el odómetro
            posicion = leer_odometro(ip)

            if posicion is not None:
                x_odometro, y_odometro, theta_odometro, vx_odometro, omega_odometro = posicion

                # Calcular el ángulo hacia el destino
                angulo_objetivo = calcular_angulo_objetivo(x_actual, y_actual, destino)

                # Calcular la diferencia angular entre el ángulo actual y el ángulo objetivo
                delta_angulo = angulo_objetivo - theta_actual
                delta_angulo = (delta_angulo + math.pi) % (2 * math.pi) - math.pi  # Normalizar el ángulo entre [-π, π]

                # Calcular la distancia euclidiana al destino
                distancia = calcular_distancia(x_actual, y_actual, destino)

                if abs(delta_angulo) > tolerancia_angular:
                    # Si la diferencia angular es mayor que la tolerancia, girar
                    omega = omega_script if delta_angulo > 0 else -omega_script
                    enviar_comandos_movimiento(ip, 0, 0, omega)  # Solo girar
                elif distancia > tolerancia_distancia:
                    # Si está alineado y la distancia es mayor que la tolerancia, avanzar
                    enviar_comandos_movimiento(ip, vx_script, 0, 0)  # Solo avanzar
                else:
                    # El robot ha llegado al destino
                    print(f"Llegó al destino: {destino}")
                    enviar_comandos_movimiento(ip, 0, 0, 0)  # Detener el robot
                    break

                # Integrar las velocidades medidas desde el odómetro
                integrar_velocidades(vx_odometro, omega_odometro, delta_t)

                # Almacenar las posiciones para el gráfico
                posiciones_robot.append([x_actual, y_actual])

            # Graficar la posición actual y la trayectoria
            trayectorias_x = [pos[0] for pos in posiciones_robot]
            trayectorias_y = [pos[1] for pos in posiciones_robot]
            trayectoria_robot.set_data(trayectorias_x, trayectorias_y)
            robot_actual.set_data([x_actual], [y_actual])  # Actualizar posición actual en la gráfica

            # Graficar la orientación del robot (una línea de longitud fija desde la posición del robot)
            longitud_flecha = 0.2  # Longitud de la flecha en metros
            orientacion_x = [x_actual, x_actual + longitud_flecha * math.cos(theta_actual)]
            orientacion_y = [y_actual, y_actual + longitud_flecha * math.sin(theta_actual)]
            orientacion_robot.set_data(orientacion_x, orientacion_y)

            plt.legend()
            plt.draw()
            plt.pause(0.1)  # Actualizar la gráfica en tiempo real

        time.sleep(1)  # Pausa antes de dirigirse al siguiente destino

    plt.ioff()  # Apagar modo interactivo

# Función principal
if __name__ == "__main__":
    ip_robot = "192.168.1.101"  # Reemplaza con la IP de tu robot

    # Lista de destinos en metros
    lista_destinos = [(0.0,2.0), (1.5, 2.0), (1.5, 0.0), (0.75, 1.0), (0.75, 1.0), (0.2, 0.8), (0.0, 0.0)]
    
    mover_robot(ip_robot, lista_destinos)
