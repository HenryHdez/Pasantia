clc;
clear all;

% Definir las posiciones para seis movimientos, con la última posición siendo la posición inicial
positions = [
    1.5, 0, 0.5, 0, 0;   % Movimiento 1: Brazo en posición inicial
    1.5, 0.5, 0.5, 0, 0;  % Movimiento 2: Extender brazo hacia adelante
    1.5, 0.5, -0.5, 0, 0;  % Movimiento 3: Bajar el brazo para agarrar la pieza
    1.5, 0.5, -0.5, 0.5, 0;  % Movimiento 4: Levantar la pieza ligeramente
    1.5, 1.0, -0.5, 0.5, 0;  % Movimiento 5: Llevar la pieza a una nueva ubicación
    1.5, 0, 0.5, 0, 0;   % Movimiento 6: Regresar a la posición inicial
];

% Definir las velocidades correspondientes para cada movimiento
velocities = [
    0.2, 0, 0, 0, 0;  % Movimiento inicial lento
    0.3, 0.3, 0, 0, 0;  % Extender brazo más rápido
    0.2, 0.2, 0.5, 0, 0;  % Bajar brazo lentamente
    0.2, 0.2, 0.3, 0.2, 0;  % Levantar la pieza con una velocidad controlada
    0.3, 0.3, 0.5, 0.3, 0;  % Llevar la pieza a la nueva posición
    0.2, 0, 0, 0, 0;  % Regresar a la posición inicial de manera suave
];

% Definir las aceleraciones correspondientes para cada movimiento
accelerations = [
    0.02, 0, 0, 0, 0;  % Aceleraciones suaves
    0.03, 0.03, 0, 0, 0;
    0.02, 0.02, 0.05, 0, 0;
    0.02, 0.02, 0.03, 0.02, 0;
    0.03, 0.03, 0.05, 0.03, 0;
    0.02, 0, 0, 0, 0;  % Aceleraciones suaves para volver a la posición inicial
];

% Definir los tiempos (en segundos) para alcanzar cada posición
times = [4, 5, 6, 5, 7, 6];  % Tiempos ajustados para cada fase del movimiento

% Definir la dirección IP del KUKA YouBot
ipAddress = '192.168.243.45';

% Llamar a la función para enviar los movimientos
enviarMovimientoBrazo(positions, velocities, accelerations, times, ipAddress);
