clear all;
rosshutdown;  % Cierra cualquier conexión previa

% Configura la IP del nodo maestro de ROS (reemplaza con la IP del YouBot)
ipAddress = '192.168.243.170';  % Cambia esta IP si es necesario
rosinit(ipAddress);  % Inicia la conexión con ROS

% Obtener la lista de tópicos disponibles
topics = rostopic('list')