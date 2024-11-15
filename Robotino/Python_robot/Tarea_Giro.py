import requests
import json
import threading
import matplotlib.pyplot as plt
import numpy as np
import time
import math

# Variables globales para las posiciones del robot
robot_position = [0, 0]         
robot_orientation = 0           
vel_rob1_mov = [0, 0, 0]        
ip = '192.168.1.101'            
robot_speed = 0.15               
obstaculo_coordenadas = []
flag_reco_x = False
flag_reco_y = False
umbral_proximidad = 0.12

# Posiciónes de los sensores
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

#Función para verificar la orientación del robot
def Verifica_orientacion(orientacion_actual, orientacion_deseada):
    orientacion_actual = np.degrees(orientacion_actual) % 360
    orientacion_deseada = orientacion_deseada % 360
    return abs(orientacion_actual - orientacion_deseada) <= 3

def mover_eje_por_eje(robot_position, destination):
    global robot_orientation, vel_rob1_mov, robot_speed, flag_reco_x, flag_reco_y
    ang_vel=0.15
    dx = destination[0] - robot_position[0]
    dy = destination[1] - robot_position[1]
    # Direcciones en X y Y
    direction_x = np.sign(dx)
    direction_y = np.sign(dy)
    # Mover en el eje X
    if abs(dx) >= 0.02 and flag_reco_y==False:
        # Verificar si está alineado en X (0° o 180°)
        flag_reco_x=True
        if (Verifica_orientacion(robot_orientation, 0) or Verifica_orientacion(robot_orientation, 360)) and direction_x > 0:
            return [robot_speed, 0.0, 0.0]
        elif Verifica_orientacion(robot_orientation, 180) and direction_x < 0:
            return [-robot_speed, 0.0, 0.0]
        else:
            if (direction_x >= 0):
                return [0.0, 0.0, ang_vel]  
            else:
                return [0.0, 0.0, ang_vel]
    # Mover en el eje Y
    elif abs(dy) >= 0.02 and flag_reco_x==False:
        flag_reco_y=True
        if Verifica_orientacion(robot_orientation, 90) and direction_y > 0:
            return [0.0, robot_speed, 0.0] 
        elif Verifica_orientacion(robot_orientation, 270) and direction_y < 0:
            return [0.0, -robot_speed, 0.0] 
        else:
            if (direction_y >= 0):
                return [0.0, 0.0, ang_vel]  
            else:
                return [0.0, 0.0, ang_vel]
            
    #Inicializar para indicar el fin del recorrido 
    flag_reco_x=False
    flag_reco_y=False
    return [0.0, 0.0, 0.0]

# Función para que el robot vaya de un punto a otro con evitación de obstáculos y sin diagonales
def mover_robot(ip, lista_destination, interval, sensor_data_container):
    global robot_position, vel_rob1_mov, robot_orientation, flag_reco_x, flag_reco_y
    destination = lista_destination[0]
    puer = 1
    evac = 1
    evitando_obstaculo = False
    lis_nueva_coor=[]
    nueva_coordenada = [0, 0] 
    distance_to_avoid_point = 1
    ori=0
    time.sleep(2)
    while True:
        # Verificar los datos de los sensores
        sensor_data = sensor_data_container[0]
        # S1-S2-S3 delanteros (X)
        # S7-S8 derecha (Y)
        # S3-S4 izquierda (-Y)
        # S5-S6 trasera (-X)
        # Verificar si algún sensor detecta un obstáculo
        if sensor_data[0] < umbral_proximidad and evitando_obstaculo==False:
            # Calcular nueva coordenada para evadir el obstáculo
            lis_nueva_coor = calcular_coordenada_evasion(robot_position, ori)
            evitando_obstaculo = True
        
        #Estructura para evitar obstaculo
        if evitando_obstaculo:
            nueva_coordenada = lis_nueva_coor[evac]
            distance_to_avoid_point = np.linalg.norm(np.array(robot_position) - np.array(nueva_coordenada))
            if distance_to_avoid_point < 0.05:
                print(">>>>>>>>Evasión<<<<<<<<")
                if evac == len(lis_nueva_coor)-1:
                    evac=1
                    evitando_obstaculo = False
                    print("Evasión completada, retomando la ruta original...")
                else:
                    print(nueva_coordenada)
                    evac += 1
            else:
                vel_rob1_mov = mover_eje_por_eje(robot_position, nueva_coordenada)
        #Estructura para continuar el recorrido
        else:
            distance_to_goal = np.linalg.norm(np.array(robot_position) - np.array(destination))
            if distance_to_goal < 0.05: 
                print(f"Robot llegó a la posición destino: {destination}")
                if puer == len(lista_destination):
                    # Detener el robot
                    vel_rob1_mov = [0.0, 0.0, 0.0]  
                    puer = 1
                    break
                else:
                    destination = lista_destination[puer]
                    puer += 1
            else:
                vel_rob1_mov = mover_eje_por_eje(robot_position, destination)
        
        # Verificar la orientación del robot y ajustar las velocidades
        Vx, Vy, Om = vel_rob1_mov
        Velo_fin = vel_rob1_mov
        if Verifica_orientacion(robot_orientation, 0) or Verifica_orientacion(robot_orientation, 360):
            Velo_fin=[abs(Vx), 0.0, Om]
            ori=0
        elif Verifica_orientacion(robot_orientation, 180): 
            # Orientación hacia el eje X negativo (180°) 
            Velo_fin=[abs(Vx), 0.0, Om]
            ori=180
        elif Verifica_orientacion(robot_orientation, 90):  
            # Orientación hacia el eje Y positivo (90°)
            Velo_fin=[abs(Vy), 0.0, Om]
            ori=90
        elif Verifica_orientacion(robot_orientation, 270):  
            # Orientación hacia el eje Y negativo (270°)
            Velo_fin=[abs(Vy), 0.0, Om]
            ori=270
        else: 
            #Solo girar
            Velo_fin=[0.0, 0.0, Om]
        enviar_comandos_movimiento(ip, Velo_fin)
        actualizar_posicion(0.25)
        time.sleep(interval)

def calcular_coordenada_evasion(robot_position, orientation):
    #Iniciar vectores de prueba
    listaCoor = [list(robot_position), list(robot_position), list(robot_position), list(robot_position)] 
    desviacion = 0.5
    nueva_coordenada = list(robot_position)
    if orientation == 0:
        # Primero mover en Y positivo, luego en X
        nueva_coordenada[1] += desviacion  
        listaCoor[1] = list(nueva_coordenada)
        listaCoor[2] = list(nueva_coordenada)
        nueva_coordenada[0] += desviacion
        listaCoor[3] = list(nueva_coordenada)
    elif orientation == 180:
        # Primero mover en Y negativo, luego en X
        nueva_coordenada[1] -= desviacion
        listaCoor[1] = list(nueva_coordenada)
        listaCoor[2] = list(nueva_coordenada)
        nueva_coordenada[0] -= desviacion
        listaCoor[3] = list(nueva_coordenada)
    elif orientation == 90:
        # Primero mover en X negativo, luego en Y negativo
        print(listaCoor)
        nueva_coordenada[0] += desviacion
        listaCoor[1] = list(nueva_coordenada)
        listaCoor[2] = list(nueva_coordenada)
        nueva_coordenada[1] += desviacion
        listaCoor[3] = list(nueva_coordenada)
        print(listaCoor)
    elif orientation == 270:
        # Primero mover en X positivo, luego en Y positivo
        nueva_coordenada[0] += desviacion
        listaCoor[1] = list(nueva_coordenada)
        listaCoor[2] = list(nueva_coordenada)
        nueva_coordenada[1] -= desviacion
        listaCoor[3] = list(nueva_coordenada)
    print(f"Coordenadas de evasión calculadas: {listaCoor}")
    return listaCoor

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
    robot_orientation = robot_orientation % (2 * np.pi)
    # Inicializar desplazamientos
    dx = 0.0
    dy = 0.0
    # Movimiento en el eje X
    if Verifica_orientacion(robot_orientation, 0) or Verifica_orientacion(robot_orientation, 360):
        direction_x = np.sign(Vx)
        if direction_x != 0:
            dx = direction_x * robot_speed * delta_t 
            dy = 0.0
        vel_rob1_mov[2] = 0.0 
    # Movimiento en el eje X negativo (180 grados)
    elif Verifica_orientacion(robot_orientation, 180):
        direction_x = np.sign(Vx)
        if direction_x != 0:
            dx = direction_x * robot_speed * delta_t 
            dy = 0.0
        vel_rob1_mov[2] = 0.0 
    # Movimiento en el eje Y (90 grados)
    elif Verifica_orientacion(robot_orientation, 90):
        direction_y = np.sign(Vy)
        if direction_y != 0:
            dx = 0.0
            dy = direction_y * robot_speed * delta_t
        vel_rob1_mov[2] = 0.0
    # Movimiento en el eje Y negativo (270 grados)
    elif Verifica_orientacion(robot_orientation, 270):
        direction_y = np.sign(Vy)
        if direction_y != 0:
            dx = 0.0
            dy = direction_y * robot_speed * delta_t
        vel_rob1_mov[2] = 0.0
    # Si no está alineado correctamente, iniciar el giro
    else:
        dx = 0.0
        dy = 0.0
        vel_rob1_mov[2] = Om 
    robot_position[0] += dx
    robot_position[1] += dy 

# Almacenar coordenadas de obstaculos
def obtener_coordenada_obstaculo(sensor_data, sensor_positions):
    obstaculos = []
    for i, valor in enumerate(sensor_data):
        if valor < umbral_proximidad:
            sensor_position = sensor_positions[i]
            x_obstaculo = robot_position[0] + valor * sensor_position[2]
            y_obstaculo = robot_position[1] + valor * sensor_position[3]
            obstaculos.append((x_obstaculo, y_obstaculo))
    return obstaculos

# Configurar la Figura para graficar
def configurar_figura(sensor_data_container):
    # Crear y parametrizar los gráficos
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 6))
    ax1.set_xlim(-1, 4)
    ax1.set_ylim(-1, 3)
    ax1.set_aspect('equal')
    ax1.grid(True)
    trayectoria, = ax1.plot([], [], 'b-', lw=2)
    robot_dot, = ax1.plot([], [], 'rs')
    robot_dot2, = ax1.plot([], [], 'k.')
    obstaculo_dots, = ax1.plot([], [], 'g*')
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
            obstaculo_coordenadas.extend(obstaculos)  
        if obstaculo_coordenadas:
            obstaculo_dots.set_data([coord[0] for coord in obstaculo_coordenadas],
                                    [coord[1] for coord in obstaculo_coordenadas])
        for i, line in enumerate(sensor_lines):
            length = sensor_data[i]
            xdata = [sensor_positions[i][0], sensor_positions[i][0] + length * sensor_positions[i][2]]  # X
            ydata = [sensor_positions[i][1], sensor_positions[i][1] + length * sensor_positions[i][3]]  # Y
            line.set_data(xdata, ydata)
        plt.draw()
        plt.pause(0.01)


if __name__ == "__main__":
    # Coordenadas a visitar
    lista_destinos = [
        [0.0, 0.0],
        [0.0, 0.5],
        [0.5, 0.5],
        [0.5, 0.0],
        [0.0, 0.0],
        [0.0, 0.1],
    ]

    # Estructura para almacenar datos de sensores
    sensor_data_container = [[0] * 9]
    # Iniciar hilo de movimiento y lectura de los sensores
    threading.Thread(target=mover_robot, args=(ip, lista_destinos, 0.2, sensor_data_container), daemon=True).start()
    threading.Thread(target=leer_sensores, args=(ip, 0.5, sensor_data_container), daemon=True).start()
    # Mostrar gráfico
    configurar_figura(sensor_data_container)