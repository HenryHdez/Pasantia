import requests
import json
import threading
import matplotlib.pyplot as plt
import numpy as np
import time

# Variables globales para las posiciones del robot
robot_position = [0, 0]     # Posición inicial en X, Y
robot_orientation = 0       # Orientación inicial del robot (en radianes)
vel_rob1_mov = [0,0,0]      # Velocidades ajustadas: Vx, Vy, Om (ajustables)
ip = '192.168.1.101'        # IP del Robotino
robot_speed = 0.05           # Velocidad base del robot (Hasta 0.5)
obstaculo_coordenadas = []

def enviar_comandos_movimiento(ip, vel_rob1):
    url = f'http://{ip}/data/omnidrive'
    datos_json = json.dumps(vel_rob1)
    try:
        headers = {'Content-Type': 'application/json'}
        response = requests.post(url, data=datos_json, headers=headers)
        
        if response.status_code == 200:
            print(f'Movimiento enviado: {vel_rob1}')
        else:
            print(f'Error en movimiento: {response.status_code} - {response.text}')
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

# Función para que el robot vaya de un punto a otro
def mover_robot(ip, lista_destination, interval):
    global robot_position
    global vel_rob1_mov
    destination = lista_destination[0]
    puer=1
    while True:
        # Estima la diferencia entre la posición de llegada y el origen
        distance_to_goal = np.linalg.norm(np.array(robot_position) - np.array(destination))
        # Estimar el margen de error
        if distance_to_goal < 0.05:  
            print(f"Robot llegó a la posición destino: {destination}")
            if puer==len(lista_destination):
                vel_rob1_mov = [0.0, 0.0, 0.0] 
                break
            else:
                destination = lista_destination[puer]
                puer=puer+1
        else:
            # Calcular la dirección hacia el destino
            direction = np.array(destination) - np.array(robot_position)
            direction = direction / np.linalg.norm(direction) 
            # Ajustar las velocidades para dirigirse al destino
            Vx = direction[0] * robot_speed
            Vy = direction[1] * robot_speed
            vel_rob1_mov = [Vx, Vy, 0.0]  
        enviar_comandos_movimiento(ip, vel_rob1_mov)
        #Solver
        actualizar_posicion(0.245)
        time.sleep(interval)

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


# Leer coordenada
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
    #Crear y parametrizar los gráficos
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
    sensor_positions = [
        [np.cos(np.pi / 2 + i * (2 * np.pi / 9)), np.sin(np.pi / 2 + i * (2 * np.pi / 9)),
         np.cos(np.pi / 2 + i * (2 * np.pi / 9)), np.sin(np.pi / 2 + i * (2 * np.pi / 9))]
        for i in range(9)
    ]
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
        robot_dot2.set_data([robot_position[0]+  0.1*np.cos(robot_orientation)], [robot_position[1]+  0.1*np.sin(robot_orientation)])
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
  
    #Coordenadas a visitar
    lista_destinos=[[0.0,0.0],
                    [0.5,0.5],
                    [0.2,0.3],
                    [0.8,0.0],
                    [0.0,0.5],
                    [0.0,0.0]]
    
    # Estructura para almacenar datos de sensores
    sensor_data_container = [[0] * 9] 

    # Iniciar hilo de movimiento y lectura de los sensores
    threading.Thread(target=mover_robot, args=(ip, lista_destinos, 0.2), daemon=True).start()
    threading.Thread(target=leer_sensores, args=(ip, 0.5, sensor_data_container), daemon=True).start()

    # Mostrar gráfico
    configurar_figura(sensor_data_container)