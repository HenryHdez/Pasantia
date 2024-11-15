import multiprocessing
import Metricas as rl
import time

# Variables compartidas para las posiciones de los robots
robot1_position = (multiprocessing.Value('d', 0.0), multiprocessing.Value('d', 0.0))  # Coordenadas x, y para el robot 1
robot2_position = (multiprocessing.Value('d', 0.0), multiprocessing.Value('d', 0.0))  # Coordenadas x, y para el robot 2
position_lock = multiprocessing.Lock()  # Lock para sincronizar el acceso a las posiciones

# Función para verificar si dos robots están en la misma posición
def estan_en_la_misma_posicion(pos1, pos2, tolerancia=0.2):
    return abs(pos1[0] - pos2[0]) < tolerancia and abs(pos1[1] - pos2[1]) < tolerancia

# Función para ejecutar el movimiento del robot y manejar la espera si está en la misma posición que otro robot
def run_robot(id, ip, lista_destinos, tiempos_parada, Dimension, nmar, robot_position, otro_robot_position):
    # Configurar parámetros iniciales para cada robot
    if id == 0:
        rl.val_iniciales(1.0, 0.0, 0.0, 0.1, 0.1, 0.1361, 0.05)
    elif id == 1:
        rl.val_iniciales(0.0, 0.0, 0.0, 0.1, 0.1, 0.1361, 0.05)
    
    # Ejecutar movimiento del robot hacia cada destino
    for destino in lista_destinos:
        reintentos = 0
        max_reintentos = 10

        while True:
            with position_lock:
                # Actualizar posición actual del robot en las variables compartidas
                robot_position[0].value = rl.x_actual
                robot_position[1].value = rl.y_actual

                # Verificar si está en la misma posición que el otro robot
                if not estan_en_la_misma_posicion(
                    (robot_position[0].value, robot_position[1].value),
                    (otro_robot_position[0].value, otro_robot_position[1].value)
                ):
                    break  # Sale del bucle si la posición está libre
            
            # Reintento si el robot detecta que está en la misma posición que el otro
            reintentos += 1
            if reintentos > max_reintentos:
                print(f"Robot {id} ha alcanzado el máximo de reintentos. Fuerza su salida.")
                break  # Forzar salida del bucle si excede el máximo de reintentos

            print(f"Robot {id} esperando en {robot_position[0].value, robot_position[1].value} debido a la proximidad con el otro robot.")
            time.sleep(0.5)

        # Llamar a `mover_robot` para moverse al siguiente destino y actualizar posición después de moverse
        rl.mover_robot(ip, [destino], tiempos_parada, Dimension, num_intermedios=0, nombre_arch=nmar)

        # Actualizar la posición después de completar el movimiento
        with position_lock:
            robot_position[0].value = rl.x_actual
            robot_position[1].value = rl.y_actual

        # Pausa breve para permitir que el otro robot actualice su posición
        time.sleep(0.1)

if __name__ == '__main__':
    # Definir destinos y tiempos de parada para cada robot
    lista_destinos_robot1 = [(1.0, 0.0), (0.75, 0.75), (1.0, 1.5), (0.5, 1.5), (0.0, 1.5), (0.25, 0.75), (0.0, 0.0), (1.0, 0.0)]
    tiempos_parada_robot1 = [3, 5, 3, 6, 8, 5, 6, 8]
    Dimensiones_robot1 = "500x600+0+10"
    lista_destinos_robot2 = [(0.0, 0.0), (0.0, 0.75), (0.0, 1.5), (0.5, 1.25), (1.0, 1.5), (1.0, 0.75), (0.0, 0.0)]
    tiempos_parada_robot2 = [4, 5, 3, 6, 5, 7, 2]
    Dimensiones_robot2 = "500x600+510+10"

    process_robot1 = multiprocessing.Process(
            target=run_robot, args=(0, "192.168.1.101", lista_destinos_robot1, tiempos_parada_robot1, Dimensiones_robot1,
                                    "metricas_robot_1.xlsx", robot1_position, robot2_position))
        
        # Crear proceso para el segundo robot y asignarle su archivo de métricas
    process_robot2 = multiprocessing.Process(
            target=run_robot, args=(1, "192.168.1.107", lista_destinos_robot2, tiempos_parada_robot2, Dimensiones_robot2,
                                    "metricas_robot_2.xlsx", robot2_position, robot1_position))

        # Iniciar ambos procesos de robots
    process_robot1.start()
    process_robot2.start()

        # Esperar a que ambos procesos terminen
    process_robot1.join()
    process_robot2.join()
