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
%>>>>>>>>>>>>>>>>Rutina de operación del Kuka<<<<<<<<<<<<<<<<<<<<<<<<<<<< 
%El primer parámetro son los angulos [A1, A2, A3, A4, A5] (en radianes). 
%El segundo son los puntos que va a seguir para llegar al punto final. 
%La función segmenta las coordenadas del recorrido para que el brazo, 
%Tenga una llegada suave
%El tercero es la IP del robot
    %-----------------Ir a la plataforma----------------------
    moverBrazo([2.8, 0.3, -3, 0.42, 0], 15, ipAddress); 
    pause(10);%Espera de 10 segundos.
    %-----------------Volver al origen------------------------
    moverBrazo ([0.0, 0.0, 0.0, 0.0, 0.0], 15, ipAddress); 
%%>>>>>>>>>>>››››› Fin Rutina de operación del KuKa<<<<<<<<<<<<<<<<<<<<<<
% Desconectar si termina el SCRIPT
if rosConectado
    disp('Cerrando conexión ROS...'); 
    rosshutdown;
end

