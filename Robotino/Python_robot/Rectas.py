import requests
import json
import threading
import matplotlib.pyplot as plt
import numpy as np
import time

# Variables globales para las posiciones del robot
robot_position = [0, 0]         # Posición inicial en X, Y
robot_orientation = 0           # Orientación inicial del robot (en radianes)
vel_rob1_mov = [0, 0, 0]        # Velocidades ajustadas: Vx, Vy, Om (ajustables)
ip = '192.168.1.101'            # IP del Robotino
robot_speed = 0.1              # Velocidad base del robot (Hasta 0.5)
obstaculo_coordenadas = []

# Umbral de proximidad para evitar obstáculos
umbral_proximidad = 0.1

# Definir las posiciones relativas de los sensores en base a la orientación del robot
sensor_positions = [
    [np.cos(np.pi / 2 + i * (2 * np.pi / 9)), np.sin(np.pi / 2 + i * (2 * np.pi / 9)),
     np.cos(np.pi / 2 + i * (2 * np.pi / 9)), np.sin(np.pi / 2 + i * (2 * np.pi / 9))]
    for i in range(9)
]

# Función para enviar comandos de movimiento al robot
def enviar_comandos_movimiento(ip, vel_rob1):
    url = f'http://{ip}/data/omnidrive'
    datos_json = json.dumps(vel_rob1)
    try:
        headers = {'Content-Type': 'application/json'}
        response = requests.post(url, data=datos_json, headers=headers)
        return response
    except requests.exceptions.RequestException as e:
        print(f'Error al enviar comandos de movimiento: {e}')

# Función para leer los sensores de proximidad del robot
def proximidad_robot(ip):
    url = f'http://{ip}/data/distancesensorarray'
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()
        else:
            print(f'Error al leer sensores: {response.status_code} - {response.text}')
            return [0] * 9
    except requests.exceptions.RequestException as e:
        print(f'Error al leer sensores: {e}')
        return [0] * 9

# Función para mover el robot en el eje X y luego en el eje Y
def mover_eje_por_eje(robot_position, destination):
    dx = destination[0] - robot_position[0]  # Diferencia en el eje X
    dy = destination[1] - robot_position[1]  # Diferencia en el eje Y
    # Movimiento en línea recta en un eje a la vez (primero X, luego Y)
    if abs(dx) > 0.02:
        # Moverse horizontalmente
        direction = np.sign(dx)
        return [direction * robot_speed, 0.0, 0.0]  # Movimiento en X
    elif abs(dy) > 0.02:
        # Moverse verticalmente
        direction = np.sign(dy)
        return [0.0, direction * robot_speed, 0.0]  # Movimiento en Y
    # Si ya está en el destino
    return [0.0, 0.0, 0.0]

import numpy as np

# Función para que el robot vaya de un punto a otro con evitación de obstáculos y sin diagonales
def mover_robot(ip, lista_destination, interval, sensor_data_container):
    global robot_position, vel_rob1_mov, robot_orientation
    destination = lista_destination[0]
    puer = 1
    evitando_obstaculo = False
    nueva_coordenada = None  # Coordenada temporal para rodear el obstáculo
    time.sleep(5)
    while True:
        # Verificar los datos de los sensores
        sensor_data = sensor_data_container[0]

        # S1-S2-S3 delanteros (X)
        # S7-S8 derecha (Y)
        # S3-S4 izquierda (-Y)
        # S5-S6 trasera (-X)
        # Verificar si algún sensor detecta un obstáculo
        if (sensor_data[0] < umbral_proximidad or sensor_data[1] < umbral_proximidad or sensor_data[2] < umbral_proximidad or
            sensor_data[3] < umbral_proximidad or sensor_data[4] < umbral_proximidad or
            sensor_data[5] < umbral_proximidad or sensor_data[6] < umbral_proximidad or
            sensor_data[7] < umbral_proximidad or sensor_data[8] < umbral_proximidad) and evitando_obstaculo==False:
            
            print("Obstáculo detectado, calculando nueva trayectoria...")

            # Calcular nueva coordenada para evadir el obstáculo
            print(robot_position)
            nueva_coordenada = calcular_coordenada_evasion(robot_position, sensor_data)
            print(nueva_coordenada)
            evitando_obstaculo = True
        
        if evitando_obstaculo:
            # Si está evitando un obstáculo, ir hacia la nueva coordenada
            if nueva_coordenada:
                distance_to_avoid_point = np.linalg.norm(np.array(robot_position) - np.array(nueva_coordenada))
                if distance_to_avoid_point < 0.05:  # Si llega a la coordenada de evasión
                    print("Evasión completada, retomando la ruta original...")
                    evitando_obstaculo = False
                    nueva_coordenada = None  # Reiniciar la coordenada de evasión
                    print("Evasión completada, retomando la ruta original...")
                else:
                    # Moverse hacia la nueva coordenada temporal (eje por eje)
                    vel_rob1_mov = mover_eje_por_eje(robot_position, nueva_coordenada)
        else:
            # Estima la diferencia entre la posición de llegada y el origen
            distance_to_goal = np.linalg.norm(np.array(robot_position) - np.array(destination))
            
            if distance_to_goal < 0.05:  # El robot ha llegado a su destino
                print(f"Robot llegó a la posición destino: {destination}")
                if puer == len(lista_destination):
                    vel_rob1_mov = [0.0, 0.0, 0.0]  # Detener el robot
                    break
                else:
                    destination = lista_destination[puer]  # Siguiente destino
                    puer += 1
            else:
                # Movimiento restringido a un eje por vez (X primero, luego Y)
                vel_rob1_mov = mover_eje_por_eje(robot_position, destination)
        
        print(vel_rob1_mov)
        # Enviar el comando de movimiento al robot
        enviar_comandos_movimiento(ip, vel_rob1_mov)
        actualizar_posicion(0.245)
        time.sleep(interval)

def calcular_coordenada_evasion(robot_position, sensor_data):
    global umbral_proximidad, vel_rob1_mov
    nueva_coordenada = None
    desviacion = 0.5  # Magnitud de la desviación
    Vx, Vy, Om = vel_rob1_mov

    # Movimiento en el eje X (Vx)
    if Vx != 0:  # Si el robot avanza en X
        if (Vx>0):
            return [robot_position[0] - desviacion, robot_position[1] + desviacion]
        else:
            return [robot_position[0] + desviacion, robot_position[1] + desviacion]
       
    # Movimiento en el eje Y (Vy)
    if Vy !=0:  # Si el robot avanza en Y
        if (Vy>0):
            return [robot_position[0]+ desviacion , robot_position[1] + desviacion ] 
        else:
            return [robot_position[0] - desviacion, robot_position[1] - desviacion]


    return nueva_coordenada


# Bucle para la ejecución continua de los sensores
def leer_sensores(ip, interval, sensor_data_container):
    while True:
        sensor_data_container[0] = proximidad_robot(ip)
        time.sleep(interval)

# Actualizar la posición
def actualizar_posicion(delta_t):
    global robot_position, robot_orientation, vel_rob1_mov
    # Descomponer las velocidades
    Vx, Vy, Om = vel_rob1_mov
    robot_orientation += Om * delta_t
    # Calcular el desplazamiento en X e Y en función de la orientación
    dx = Vx * np.cos(robot_orientation) - Vy * np.sin(robot_orientation)
    dy = Vx * np.sin(robot_orientation) + Vy * np.cos(robot_orientation)
    # Actualizar la posición del robot
    robot_position[0] += dx * delta_t
    robot_position[1] += dy * delta_t

# Leer coordenada de obstáculo
def obtener_coordenada_obstaculo(sensor_data, sensor_positions, threshold=0.1):
    obstaculos = []
    for i, valor in enumerate(sensor_data):
        if valor < threshold:
            sensor_position = sensor_positions[i]
            x_obstaculo = robot_position[0] + valor * sensor_position[2]
            y_obstaculo = robot_position[1] + valor * sensor_position[3]
            obstaculos.append((x_obstaculo, y_obstaculo))
    return obstaculos

# Configurar la Figura para graficar
def configurar_figura(sensor_data_container):
    # Crear y parametrizar los gráficos
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 6))
    ax1.set_xlim(-2, 2)
    ax1.set_ylim(-2, 2)
    ax1.set_aspect('equal')
    ax1.grid(True)
    trayectoria, = ax1.plot([], [], 'b-', lw=2)
    robot_dot, = ax1.plot([], [], 'ro')
    robot_dot2, = ax1.plot([], [], 'b.')
    obstaculo_dots, = ax1.plot([], [], 'go')
    ax2.set_xlim(-1.5, 1.5)
    ax2.set_ylim(-1.5, 1.5)
    ax2.set_aspect('equal')
    ax2.grid(True)
    #Agregar circulo y visualización de los sensores
    circulo = plt.Circle((0, 0), 1, color='black', fill=False)
    ax2.add_artist(circulo)
    sensor_colors = ['red', 'green', 'blue', 'orange', 'purple', 'brown', 'pink', 'gray', 'cyan']
    sensor_lines = [ax2.plot([pos[0], pos[0]], [pos[1], pos[1]], color=sensor_colors[i], label=f'Sensor {i+1}')[0] for i, pos in enumerate(sensor_positions)]
    for i, pos in enumerate(sensor_positions):
        ax2.text(pos[0] * 1.2, pos[1] * 1.2, f'S{i+1}', color=sensor_colors[i], fontsize=12, ha='center')

    # Iniciar las listas para la trayectoria del robot
    posiciones_x, posiciones_y = [robot_position[0]], [robot_position[1]]
    plt.ion()
    while True:
        # Actualizar trayectoria
        posiciones_x.append(robot_position[0])
        posiciones_y.append(robot_position[1])
        trayectoria.set_data(posiciones_x, posiciones_y)
        robot_dot.set_data([robot_position[0]], [robot_position[1]])
        robot_dot2.set_data([robot_position[0] + 0.1 * np.cos(robot_orientation)], [robot_position[1] + 0.1 * np.sin(robot_orientation)])
        sensor_data = sensor_data_container[0]
        obstaculos = obtener_coordenada_obstaculo(sensor_data, sensor_positions)
        if obstaculos:
            obstaculo_coordenadas.extend(obstaculos)  # Agregar obstáculos detectados a la lista

        # Actualizar los puntos de obstáculos
        if obstaculo_coordenadas:
            obstaculo_dots.set_data([coord[0] for coord in obstaculo_coordenadas],
                                    [coord[1] for coord in obstaculo_coordenadas])
        for i, line in enumerate(sensor_lines):
            length = sensor_data[i]
            xdata = [sensor_positions[i][0], sensor_positions[i][0] + length * sensor_positions[i][2]]  # X
            ydata = [sensor_positions[i][1], sensor_positions[i][1] + length * sensor_positions[i][3]]  # Y
            line.set_data(xdata, ydata)
        plt.draw()
        plt.pause(0.1)

if __name__ == "__main__":
    # Coordenadas a visitar
    lista_destinos = [
        [0.0, 0.0],
        [0.0, 0.2],
        [0.5, 0.5],
        [0.8, 0.8],
        [0.1, 0.8],
        [0.0, 0.0]
    ]

    # Estructura para almacenar datos de sensores
    sensor_data_container = [[0] * 9]

    # Iniciar hilo de movimiento y lectura de los sensores
    threading.Thread(target=mover_robot, args=(ip, lista_destinos, 0.2, sensor_data_container), daemon=True).start()
    threading.Thread(target=leer_sensores, args=(ip, 0.5, sensor_data_container), daemon=True).start()

    # Mostrar gráfico
    configurar_figura(sensor_data_container)
