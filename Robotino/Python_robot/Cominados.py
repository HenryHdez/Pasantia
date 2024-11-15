import requests
import json
import threading
import matplotlib.pyplot as plt
import numpy as np
import time

# Variables globales para las posiciones del robot
robot_position = [0, 0]  # Posición inicial en X, Y
robot_orientation = 0  # Orientación inicial del robot (en radianes)
vel_rob1_mov = [0.1, 0.0, 0.0]  # Velocidades ajustadas: Vx, Vy, Om (ajustables)
ip = '192.168.1.101'  # IP del Robotino

# Función para enviar comandos de movimiento al robot
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

# Función para leer los sensores del robot
def leer_sensores(ip):
    url = f'http://{ip}/data/distancesensorarray'
    
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()  # Devolver los datos de los sensores como lista
        else:
            print(f'Error al leer sensores: {response.status_code} - {response.text}')
            return [0] * 9  # Valores nulos si falla
        
    except requests.exceptions.RequestException as e:
        print(f'Error al leer sensores: {e}')
        return [0] * 9  # Valores nulos si hay error

# Función para ejecutar el movimiento repetidamente en un hilo
def mover_robot_repetidamente(ip, interval, vel_rob1):
    while True:
        enviar_comandos_movimiento(ip, vel_rob1)
        actualizar_posicion(0.35)  # Actualiza la posición del robot
        time.sleep(interval)  # Espera el tiempo definido antes de enviar el próximo comando

# Función para ejecutar la lectura de sensores repetidamente
def leer_sensores_repetidamente(ip, interval, sensor_data_container):
    while True:
        sensor_data_container[0] = leer_sensores(ip)
        time.sleep(interval)  # Espera el tiempo definido antes de la próxima lectura

# Función para actualizar la posición del robot en base a las velocidades
def actualizar_posicion(delta_t):
    global robot_position, robot_orientation, vel_rob1_mov
    
    Vx, Vy, Om = vel_rob1_mov  # Descomponer las velocidades
    robot_orientation += Om * delta_t  # Actualizar la orientación con Om (giro)
    
    # Calcular el desplazamiento en X e Y en función de la orientación
    dx = Vx * np.cos(robot_orientation) - Vy * np.sin(robot_orientation)
    dy = Vx * np.sin(robot_orientation) + Vy * np.cos(robot_orientation)
    
    # Actualizar la posición del robot
    robot_position[0] += dx * delta_t
    robot_position[1] += dy * delta_t

    # Mostrar la posición actual para ver el cambio
    print(f"Posición actual: X={robot_position[0]:.2f}, Y={robot_position[1]:.2f}, Orientación={robot_orientation:.2f} rad")

# Función para configurar la figura con dos subplots
def configurar_figura(sensor_data_container):
    # Crear figura con dos subplots
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 6))  # Dos subplots lado a lado

    # Configuración del gráfico de la trayectoria (ax1)
    ax1.set_xlim(-2, 2)  # Limitar el eje X
    ax1.set_ylim(-2, 2)  # Limitar el eje Y
    ax1.set_aspect('equal')  # Hacer que el gráfico sea cuadrado
    trayectoria, = ax1.plot([], [], 'b-', lw=2)  # Línea azul para el recorrido
    robot_dot, = ax1.plot([], [], 'ro')  # Punto rojo para la posición actual del robot

    # Configuración del gráfico de los sensores (ax2)
    ax2.set_xlim(-1.5, 1.5)  # Limitar el eje X
    ax2.set_ylim(-1.5, 1.5)  # Limitar el eje Y
    ax2.set_aspect('equal')  # Hacer que el gráfico sea cuadrado

    # Dibujar el círculo del robot en ax2
    circulo = plt.Circle((0, 0), 1, color='black', fill=False)
    ax2.add_artist(circulo)

    # Calcular los ángulos equidistantes para los 9 sensores
    sensor_positions = [
        [np.cos(np.pi / 2 + i * (2 * np.pi / 9)), np.sin(np.pi / 2 + i * (2 * np.pi / 9)),
         np.cos(np.pi / 2 + i * (2 * np.pi / 9)), np.sin(np.pi / 2 + i * (2 * np.pi / 9))]
        for i in range(9)
    ]

    # Colores para cada sensor
    sensor_colors = ['red', 'green', 'blue', 'orange', 'purple', 'brown', 'pink', 'gray', 'cyan']

    # Inicializar las líneas de los sensores con diferentes colores
    sensor_lines = [ax2.plot([pos[0], pos[0]], [pos[1], pos[1]], color=sensor_colors[i], label=f'Sensor {i+1}')[0] for i, pos in enumerate(sensor_positions)]

    # Etiquetar los sensores en ax2
    for i, pos in enumerate(sensor_positions):
        ax2.text(pos[0] * 1.2, pos[1] * 1.2, f'S{i+1}', color=sensor_colors[i], fontsize=12, ha='center')

    # Inicializar las listas para la trayectoria del robot
    posiciones_x, posiciones_y = [robot_position[0]], [robot_position[1]]

    # Modo interactivo de Matplotlib
    plt.ion()

    # Bucle de actualización en tiempo real
    while True:
        # Actualizar trayectoria
        posiciones_x.append(robot_position[0])
        posiciones_y.append(robot_position[1])
        trayectoria.set_data(posiciones_x, posiciones_y)
        robot_dot.set_data([robot_position[0]], [robot_position[1]])

        # Actualizar sensores
        sensor_data = sensor_data_container[0]
        for i, line in enumerate(sensor_lines):
            length = sensor_data[i]  # Longitud de la barrita según el valor del sensor
            xdata = [sensor_positions[i][0], sensor_positions[i][0] + length * sensor_positions[i][2]]  # X
            ydata = [sensor_positions[i][1], sensor_positions[i][1] + length * sensor_positions[i][3]]  # Y
            line.set_data(xdata, ydata)  # Actualizar los datos de la línea

        # Refrescar gráficos
        plt.draw()
        plt.pause(0.1)  # Pausar brevemente para refrescar la figura

# Función principal
def main():
    # Contenedor para almacenar los datos de los sensores
    sensor_data_container = [[0] * 9]  # Se usa una lista dentro de otra lista para evitar problemas de referencia en el hilo

    # Iniciar el hilo para mover el robot repetidamente
    threading.Thread(target=mover_robot_repetidamente, args=(ip, 0.3, vel_rob1_mov), daemon=True).start()

    # Iniciar el hilo para leer los sensores repetidamente
    threading.Thread(target=leer_sensores_repetidamente, args=(ip, 0.2, sensor_data_container), daemon=True).start()

    # Configurar y mostrar la figura con los dos subplots
    configurar_figura(sensor_data_container)

if __name__ == "__main__":
    main()
