clc;
clear all;

% Definir las posiciones para cuatro movimientos (cinco filas, cinco columnas para cinco articulaciones)
positions = [
    3, 0, 0, 0, 0;   % Movimiento 1: Brazo en posición inicial
    3, 0, 0, 0, 0;   % Movimiento 1: Brazo en posición inicial
    3, 0.5, 0.5, 0, 0;  % Movimiento 2: Extender brazo hacia adelante
    3, 0.5, -0.25, 0, 0;  % Movimiento 3: Bajar el brazo para agarrar la pieza
    3, 0.5, -0.25, 0.25, 0;  % Movimiento 4: Levantar la pieza ligeramente
    3, 1.0, -0.25, 0.25, 0;  % Movimiento 5: Llevar la pieza a una nueva ubicación
];

% Definir las velocidades correspondientes para cada movimiento
velocities = [
    0.2, 0, 0, 0, 0;  % Movimiento inicial lento
    0.0, 0.0, 0.0, 0.0, 0.0;  % Bajar brazo lentamente
    0.3, 0.3, 0, 0, 0;  % Extender brazo más rápido
    0.0, 0.0, 0.0, 0.0, 0.0;  % Bajar brazo lentamente
    0.2, 0.2, 0.3, 0.2, 0;  % Levantar la pieza con una velocidad controlada
    0.0, 0.0, 0.0, 0.0, 0.0;  % Mantener la posición final
];

% Definir las aceleraciones correspondientes para cada movimiento
accelerations = [
    0.02, 0, 0, 0, 0;  % Aceleraciones suaves
    0.0, 0.0, 0.0, 0.0, 0.0;  % Bajar brazo lentamente
    0.03, 0.03, 0, 0, 0;
    0.0, 0.0, 0.0, 0.0, 0.0;
    0.02, 0.02, 0.03, 0.02, 0;
    0.0, 0.0, 0.0, 0.0, 0.0;  % Aceleraciones finales en cero para mantener la posición
];

% Definir los tiempos (en segundos) para alcanzar cada posición
times = [10, 5, 6, 5, 7, 8];  % Tiempos ajustados para cada fase del movimiento

% Definir la dirección IP del KUKA YouBot
ipAddress = '192.168.243.45';

% Llamar a la función para enviar los movimientos
enviarMovimientoBrazo(positions, velocities, accelerations, times, ipAddress);
