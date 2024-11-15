clc;
clear all;
rosshutdown;  % Cierra cualquier conexión previa

% Configura la IP del nodo maestro de ROS (reemplaza con la IP del YouBot)
ipAddress = '192.168.243.170';  % Cambia esta IP si es necesario
rosinit(ipAddress);  % Inicia la conexión con ROS

% Crear el publicador para cancelar la trayectoria actual
cancelTrajPub = rospublisher('/arm_1/arm_controller/follow_joint_trajectory/cancel', 'actionlib_msgs/GoalID');

% Crear el mensaje de cancelación
cancelMsg = rosmessage(cancelTrajPub);

% Enviar el mensaje de cancelación para detener cualquier trayectoria en curso
send(cancelTrajPub, cancelMsg);

disp('Trajectoria cancelada.');

% Pausar por unos segundos para permitir que se procese la cancelación
pause(2);

% Enviar una nueva trayectoria o un comando de posición
% Puedes utilizar el código anterior que te proporcioné para enviar una nueva trayectoria

% Cerrar la conexión con ROS
rosshutdown;

