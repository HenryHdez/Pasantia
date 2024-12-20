clc;
clear;
% Definir la dirección IP del KUKA YouBot
ipAddress = '192.168.128.201';
rosshutdown;
rosinit(ipAddress);

%Definir recorrido rapido
positions = [2, 0.3, -1.5, 0, 0];
velocities = [0.051, 0.051, 0, 0, 0];
accelerations = [0.01, 0.01, 0, 0, 0];
times = [1];
enviarMovimientoBrazo(positions, velocities, accelerations, times, ipAddress);

% Ajuste fino
positions = [1, 0.1, -1, 0.11, 0;
             2, 0.15, -2, 0.22, 0;
             2.78, 0.15, -2, 0.22, 0;
             2.78, 0.3, -3.1, 0.42, 0;];

velocities = [0.2, 0.2, 0.2, 0.2, 0.2;
              0.1, 0.1, 0.1, 0.4, 0.4;
              0.05, 0.05, 0.05, 0.05, 0.05;
              0.01, 0.01, 0.01, 0.01, 0.01];

time1=[0.08, 0.08, 0.08, 0.08;];

moverArticulaciones(positions, velocities, time1, ipAddress);

rosshutdown;