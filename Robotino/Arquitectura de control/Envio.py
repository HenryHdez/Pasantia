import requests
import json
import threading
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import numpy as np

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
        threading.Event().wait(interval)  # Espera el tiempo definido antes de enviar el próximo comando

# Función para ejecutar la lectura de sensores repetidamente
def leer_sensores_repetidamente(ip, interval, sensor_data_container):
    while True:
        sensor_data_container[0] = leer_sensores(ip)
        threading.Event().wait(interval)  # Espera el tiempo definido antes de la próxima lectura

# Función para actualizar el gráfico en cada frame
def actualizar_grafico(frame, sensor_data_container, sensor_lines, sensor_positions):
    sensor_data = sensor_data_container[0]

    # Actualizar las líneas de los sensores basadas en los datos
    for i, line in enumerate(sensor_lines):
        length = sensor_data[i]  # Longitud de la barrita según el valor del sensor
        xdata = [sensor_positions[i][0], sensor_positions[i][0] + length * sensor_positions[i][2]]  # X
        ydata = [sensor_positions[i][1], sensor_positions[i][1] + length * sensor_positions[i][3]]  # Y
        line.set_data(xdata, ydata)  # Actualizar los datos de la línea

    return sensor_lines

# Configuración del gráfico cuadrado en tiempo real
def graficar_sensores(ip, sensor_data_container):
    fig, ax = plt.subplots()
    ax.set_xlim(-1.5, 1.5)  # Limitar el eje X
    ax.set_ylim(-1.5, 1.5)  # Limitar el eje Y
    ax.set_aspect('equal')  # Hacer que el gráfico sea cuadrado

    # Dibujar el círculo del robot
    circulo = plt.Circle((0, 0), 1, color='black', fill=False)
    ax.add_artist(circulo)

    # Calcular los ángulos equidistantes para los 9 sensores
    sensor_positions = [
        [np.cos(np.pi / 2 + i * (2 * np.pi / 9)), np.sin(np.pi / 2 + i * (2 * np.pi / 9)),
         np.cos(np.pi / 2 + i * (2 * np.pi / 9)), np.sin(np.pi / 2 + i * (2 * np.pi / 9))]
        for i in range(9)
    ]

    # Colores para cada sensor
    sensor_colors = ['red', 'green', 'blue', 'orange', 'purple', 'brown', 'pink', 'gray', 'cyan']

    # Inicializar las líneas de los sensores con diferentes colores
    sensor_lines = [ax.plot([pos[0], pos[0]], [pos[1], pos[1]], color=sensor_colors[i], label=f'Sensor {i+1}')[0] for i, pos in enumerate(sensor_positions)]

    # Etiquetar los sensores
    for i, pos in enumerate(sensor_positions):
        ax.text(pos[0] * 1.2, pos[1] * 1.2, f'S{i+1}', color=sensor_colors[i], fontsize=12, ha='center')

    # Iniciar la animación para actualizar el gráfico en intervalos regulares
    anim = FuncAnimation(fig, actualizar_grafico, fargs=(sensor_data_container, sensor_lines, sensor_positions), interval=500)

    # Mostrar el gráfico con leyenda
    plt.show()

# Función principal
def main():
    ip = '192.168.1.101'  # IP del Robotino
    vel_rob1_mov = [0.0, 0.0, 0.0]  # Comandos de movimiento (Vx, Vy, Omega)
    
    # Contenedor para almacenar los datos de los sensores
    sensor_data_container = [[0] * 9]  # Se usa una lista dentro de otra lista para evitar problemas de referencia en el hilo

    # Iniciar el hilo para mover el robot repetidamente
    threading.Thread(target=mover_robot_repetidamente, args=(ip, 0.2, vel_rob1_mov), daemon=True).start()

    # Iniciar el hilo para leer los sensores repetidamente
    threading.Thread(target=leer_sensores_repetidamente, args=(ip, 0.5, sensor_data_container), daemon=True).start()

    # Iniciar la gráfica en tiempo real
    graficar_sensores(ip, sensor_data_container)

if __name__ == "__main__":
    main()
