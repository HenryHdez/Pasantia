clc,clear;
ipAddress='192.168.1.150'; %IP del KuKa
% Establecer conexión mediante ROS con el Robot Kuka 
rosConectado = false;
try
    disp('Iniciando conexión ROS...');
    rosshutdown;
    rosinit(ipAddress);
    rosConectado = true;
catch
    rosnode list;
    rosConectado = true;
end

%%>>>>>>>>>>>>>>> Rutina de operación del Kuka <<<<<<<<<<< 
% Parametro 1 velocidadX: velocidad en el eje X 
% Parametro 2 velocidadY: velocidad en el eje Y 
% Parametro 3 velocidadTheta: velocidad angular
% Parámetro 4 dirección IP
% Parámetro 5 Tiempo de ejecución
%-------Mover hacia adelante-------
moverCarro(0.3, 0.0, 0.0, ipAddress, 2);
%------Mover hacia atras------------
moverCarro (-0.3, 0.0, 0.0, ipAddress, 2); 
%------Mover hacia la derecha------------
moverCarro (0.0, 0.5, 0.0, ipAddress, 2);
%------Mover hacia la izquierda------------
moverCarro(0.0, -0.5, 0.0, ipAddress, 2);
%------Mover hacia en sentido horario------------
moverCarro(0.0, 0.0, 0.1, ipAddress, 2); 
%------Mover hacia en sentido anti-horario------------
moverCarro (0.0, 0.0, -0.1, ipAddress, 2);
%------Mover en diagonal------------
moverCarro (0.1, 0.1, 0.0, ipAddress, 2);
%Detener
moverCarro (0.0, 0.0, 0.0, ipAddress, 2);
%%>>>>>>>>>>> Fin Rutina de operación del Kuka<<<<<<<
% Desconectar si termina el SCRIPT
if rosConectado
    disp('Cerrando conexión ROS...'); 
    rosshutdown;
end

