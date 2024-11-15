clc;
clear;

% Definir la dirección IP del KUKA YouBot
ipAddress = '192.168.1.150';
rosshutdown;
rosinit(ipAddress);

disp(">>>>>>>>>Rutina Robotino 1<<<<<<<<<<<<<<<<")
%%%>>>>>>>>>>>>>>>>>>>>>>>>>>>Tomar pieza 1<<<<<<<<<<<<<<<<<<<<<<<<<
%Mover al punto 1
moverBrazo([2.8, 0.3, -1, 0.2, 0], 15, ipAddress);
%Abrir gripper para que no arrastre la pieza
gripperPub = rospublisher('/arm_1/gripper_controller/position_command', ...
    'brics_actuator/JointPositions');
abrirGripper(gripperPub);
%Mover al punto de tomar muestra 1
moverBrazo([2.8, 0.3, -3, 0.42, 0], 15, ipAddress);
cerrarGripper(gripperPub);
%>>>>>>>>>>>>>>Mover a una posición intermedia<<<<<<<<<<<<<<<<<<<<<<<<<<<<
moverBrazo([0.5,0.3,-1.5,0.22,0], 15, ipAddress);
%%%>>>>>>>>>>>>>>>>>>>>>>Poner pieza en el robotino 1<<<<<<<<<<<<<<<<<<<<<
moverBrazo([0.1, 0.3, -2.5, 0.35, 0], 15, ipAddress);
Soltarelemento(ipAddress, 5);
%llevar al origen
moverBrazo([0.1,0.1,0.1,0.1,0], 15, ipAddress);

%>>>>>>>>>>>>>>>>>>Mover el carro a la segunda posición<<<<<<<<<<<<<<<<<<<
%Negativo derecha
%Positivo izquierda
%0.1 m/s durante 4 segundos
moverCarro(-0.3, 0, 0, 3, ipAddress);

disp(">>>>>>>>>Rutina Robotino 2<<<<<<<<<<<<<<<<")
%%%>>>>>>>>>>>>>>>>>>>>>>>>>>>Tomar pieza 2<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
%Mover al punto 1
moverBrazo([2.8, 0.3, -1, 0.2, 0], 15, ipAddress);
%Abrir gripper para que no arrastre la pieza
gripperPub = rospublisher('/arm_1/gripper_controller/position_command', ...
    'brics_actuator/JointPositions');
abrirGripper(gripperPub);
%Mover al punto de tomar muestra 1
moverBrazo([2.8, 0.3, -3, 0.42, 0], 15, ipAddress);
cerrarGripper(gripperPub);
%>>>>>>>>>>>>>>Mover a una posición intermedia<<<<<<<<<<<<<<<<<<<<<<<<<<<<
moverBrazo([0.5,0.3,-1.5,0.22,0], 15, ipAddress);
%%%>>>>>>>>>>>>>>>>>>>>>>Poner pieza en el robotino 1<<<<<<<<<<<<<<<<<<<<<
moverBrazo([0.1, 0.3, -2.5, 0.35, 0], 15, ipAddress);
Soltarelemento(ipAddress, 5);
%llevar al origen
moverBrazo([0.1,0.1,0.1,0.1,0], 15, ipAddress);

%>>>>>>>>>>>>>>>>>>Mover el carro a la posición de origen<<<<<<<<<<<<<<<<<<<
%Negativo derecha
%Positivo izquierda
%0.25 m/s durante 4 segundos
moverCarro(0.3, 0, 0,3, ipAddress);