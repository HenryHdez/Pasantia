clc;
clear;

% Definir la dirección IP del KUKA YouBot
ipAddress = '192.168.1.150';
rosshutdown;
rosinit(ipAddress);

% Crear una estructura para almacenar métricas
metricas = struct('Iteracion', [], 'TiempoTotal', [], 'DistanciaRecorrida', [], ...
                  'DistanciaAlObjetivo', [], 'VelocidadLineal', [], 'Orientacion', [], ...
                  'DeteccionesObstaculos', [], 'Disponibilidad', [], 'TiempoCiclo', [], ...
                  'ConsumoEnergia', [], 'CoordenadaX', [], 'CoordenadaY', []);

% Definir valores iniciales para las métricas
tiempoTotal = tic;  % Tiempo total de la rutina
tiempoOperativo = 0;  % Tiempo acumulado en movimiento
potenciaRobot = 88.8;  % Potencia estimada en vatios (W), 12V 7.5Ah consumidos en 2 horas
deteccionesObstaculos = 0;  % Contador de obstáculos detectados

disp(">>>>>>>>>Rutina Robotino 1<<<<<<<<<<<<<<<<")

%%%>>>>>>>>>>>>>>>>>>>>>>>>>>>Tomar pieza 1<<<<<<<<<<<<<<<<<<<<<<<<<
% Mover al punto 1 y medir el tiempo de ciclo
tic;  % Iniciar temporizador para tiempo de ciclo
moverBrazo([2.8, 0.3, -1, 0.2, 0], 15, ipAddress);
tiempoCiclo = toc;
tiempoOperativo = tiempoOperativo + tiempoCiclo;

% Abrir gripper para que no arrastre la pieza
gripperPub = rospublisher('/arm_1/gripper_controller/position_command', ...
    'brics_actuator/JointPositions');
abrirGripper(gripperPub);

% Mover al punto de tomar muestra 1
tic;
moverBrazo([2.8, 0.3, -3, 0.42, 0], 15, ipAddress);
tiempoCiclo = toc;
tiempoOperativo = tiempoOperativo + tiempoCiclo;
cerrarGripper(gripperPub);

% Guardar métricas después de tomar la pieza
metricas = registrarMetricas(metricas, tiempoTotal, tiempoOperativo, potenciaRobot, deteccionesObstaculos);

%%%>>>>>>>>>>>>>>Mover a una posición intermedia<<<<<<<<<<<<<<<<<<<<<<
tic;
moverBrazo([0.5,0.3,-1.5,0.22,0], 15, ipAddress);
tiempoCiclo = toc;
tiempoOperativo = tiempoOperativo + tiempoCiclo;

%%%>>>>>>>>>>>>>>>>>>>>>>Poner pieza en el robotino 1<<<<<<<<<<<<<<<<<
tic;
moverBrazo([0.1, 0.3, -2.5, 0.35, 0], 15, ipAddress);
tiempoCiclo = toc;
tiempoOperativo = tiempoOperativo + tiempoCiclo;
Soltarelemento(ipAddress, 5);

% Llevar al origen
moverBrazo([0.1,0.1,0.1,0.1,0], 15, ipAddress);

% Guardar métricas después de completar el movimiento
metricas = registrarMetricas(metricas, tiempoTotal, tiempoOperativo, potenciaRobot, deteccionesObstaculos);

% Mover el carro a la segunda posición (métricas de movimiento del carro)
tic;
moverCarro(-0.3, 0, 0, 3, ipAddress);
pause(3);
tiempoCiclo = toc;
tiempoOperativo = tiempoOperativo + tiempoCiclo;
metricas = registrarMetricas(metricas, tiempoTotal, tiempoOperativo, potenciaRobot, deteccionesObstaculos);

disp(">>>>>>>>>Rutina Robotino 2<<<<<<<<<<<<<<<<")
%%%>>>>>>>>>>>>>>>>>>>>>>>>>>>Tomar pieza 2<<<<<<<<<<<<<<<<<<<<<<<<<
% Repetir las mismas operaciones para el Robotino 2 y registrar métricas
moverBrazo([2.8, 0.3, -1, 0.2, 0], 15, ipAddress);
abrirGripper(gripperPub);
moverBrazo([2.8, 0.3, -3, 0.42, 0], 15, ipAddress);
cerrarGripper(gripperPub);
metricas = registrarMetricas(metricas, tiempoTotal, tiempoOperativo, potenciaRobot, deteccionesObstaculos);

moverBrazo([0.5,0.3,-1.5,0.22,0], 15, ipAddress);
moverBrazo([0.1, 0.3, -2.5, 0.35, 0], 15, ipAddress);
Soltarelemento(ipAddress, 5);
moverBrazo([0.1,0.1,0.1,0.1,0], 15, ipAddress);
metricas = registrarMetricas(metricas, tiempoTotal, tiempoOperativo, potenciaRobot, deteccionesObstaculos);

% Mover el carro a la posición de origen
tic;
moverCarro(0.3, 0, 0, 3, ipAddress);
pause(3);
tiempoCiclo = toc;
tiempoOperativo = tiempoOperativo + tiempoCiclo;
metricas = registrarMetricas(metricas, tiempoTotal, tiempoOperativo, potenciaRobot, deteccionesObstaculos);

% Guardar las métricas en un archivo de Excel
guardarMetricasEnExcel(metricas, 'MetricasRobotino.xlsx');

rosshutdown;

%% Función para registrar métricas en cada movimiento
function metricas = registrarMetricas(metricas, tiempoTotal, tiempoOperativo, potenciaRobot, deteccionesObstaculos)
    tiempoAcumulado = toc(tiempoTotal);
    disponibilidad = (tiempoOperativo / tiempoAcumulado) * 100;
    consumoEnergia = (potenciaRobot * tiempoOperativo) / 3600;
    [posicionX, posicionY] = obtenerPosicionActual();  % Obtener la posición actual del robot
    
    % Calcular métricas adicionales
    distanciaRecorrida = rand();  % Simulado
    distanciaAlObjetivo = rand();  % Simulado
    velocidadLineal = 0.1;  % Simulado
    orientacion = rand();  % Simulado

    % Agregar datos a la estructura de métricas
    metricas.Iteracion(end+1) = length(metricas.Iteracion) + 1;
    metricas.TiempoTotal(end+1) = tiempoAcumulado;
    metricas.DistanciaRecorrida(end+1) = distanciaRecorrida;
    metricas.DistanciaAlObjetivo(end+1) = distanciaAlObjetivo;
    metricas.VelocidadLineal(end+1) = velocidadLineal;
    metricas.Orientacion(end+1) = orientacion;
    metricas.DeteccionesObstaculos(end+1) = deteccionesObstaculos;
    metricas.Disponibilidad(end+1) = disponibilidad;
    metricas.TiempoCiclo(end+1) = tiempoOperativo;
    metricas.ConsumoEnergia(end+1) = consumoEnergia;
    metricas.CoordenadaX(end+1) = posicionX;
    metricas.CoordenadaY(end+1) = posicionY;
end

%% Función para guardar métricas en un archivo Excel
function guardarMetricasEnExcel(metricas, nombreArchivo)
    % Crear una tabla para almacenar las métricas
    datosMetricas = table(metricas.Iteracion', metricas.TiempoTotal', metricas.DistanciaRecorrida', ...
                          metricas.DistanciaAlObjetivo', metricas.VelocidadLineal', metricas.Orientacion', ...
                          metricas.DeteccionesObstaculos', metricas.Disponibilidad', metricas.TiempoCiclo', ...
                          metricas.ConsumoEnergia', metricas.CoordenadaX', metricas.CoordenadaY', ...
                          'VariableNames', {'Iteracion', 'TiempoTotal', 'DistanciaRecorrida', 'DistanciaAlObjetivo', ...
                                            'VelocidadLineal', 'Orientacion', 'DeteccionesObstaculos', ...
                                            'Disponibilidad', 'TiempoCiclo', 'ConsumoEnergia', 'CoordenadaX', 'CoordenadaY'});

    % Guardar la tabla en un archivo Excel
    writetable(datosMetricas, nombreArchivo);
    disp(['Métricas guardadas en el archivo: ', nombreArchivo]);
end

%% Función para obtener la posición actual del robot (simulada)
function [posX, posY] = obtenerPosicionActual()
    % Aquí, implementa la función para obtener la posición actual real del robot, si está disponible.
    % Esta función se simula en este ejemplo con valores aleatorios.
    posX = rand();  % Valor simulado
    posY = rand();  % Valor simulado
end
