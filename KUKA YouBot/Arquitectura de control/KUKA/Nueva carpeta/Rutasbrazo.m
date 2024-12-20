clc;
clear;

% Definir las posiciones para tres movimientos (tres filas, cinco columnas para cinco articulaciones)
positions = [
    2.7, 0, 0, 0, 0;  
    2.7, 0.35, 0, 0, 0;
    2.7, 0.35, -0.8, 0, 0;
    2.7, 0.35, -1.6, 0, 0;
    2.7, 0.35, -2.6, 0, 0;
    2.7, 0.35, -2.6, 0.4, 0;  % Movimiento 1
];

% Definir las velocidades correspondientes para cada movimiento
velocities = [
    0.1, 0, 0, 0, 0;
    0, 0.1, 0, 0, 0;
    0, 0, 0.2, 0, 0;
    0, 0, 0.01, 0, 0;
    0, 0, 0.01, 0, 0;
    0, 0, 0, 0.1, 0;
];

% Definir las aceleraciones correspondientes para cada movimiento
accelerations = [
    0.01, 0, 0, 0, 0;
    0, 0.01, 0, 0, 0;
    0, 0, 0.2, 0, 0;
    0, 0, 0.1, 0, 0;
    0, 0, 0.05, 0, 0;
    0, 0, 0, 0.01, 0;
];

% Definir los tiempos (en segundos) para alcanzar cada posición
times = [3, 3, 2 , 2, 1, 1];

% Definir la dirección IP del KUKA YouBot
ipAddress = '192.168.28.201';

% Llamar a la función para enviar los movimientos
enviarMovimientoBrazo(positions, velocities, accelerations, times, ipAddress);
