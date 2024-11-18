%Valores iniciales
url1 = 'http://192.168.128.199/data/omnidrive';  % Robotino 1
url2 = 'http://192.168.128.92/data/omnidrive';   % Robotino 2
url3 = '192.168.128.192';   % KukaBot
ipAddress = url3;
rosshutdown;
rosinit(ipAddress);

%Frecuencia de actualización
Freq = 0:100:1000;
%Vector que almacenara los hilos de cada robot
FutRob1 = cell(1, 6);
FutRob2 = cell(1, 6);
t_parada = 8;

disp('>>>>>>>>>>>Rutina Robotino 1<<<<<<<<<<<<')
%>>>>>>>>>>>>>>>>>>>>Movimientos<<<<<<<<<<<<<<<<<<<<<<
%Cargar pieza
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

%Mover robotino 1
% Crear hilos en paralelo con parfeval para Robotino 1
%Ida
%Velocidades (Vx, Vy, Omega)
VelRob1 = [0.2, 0.0, 0.0];
for i = 1:10
    vx = VelRob1(1);
    vy = VelRob1(2);
    om = VelRob1(3);
    FutRob1{i} = parfeval(@EnviarMovRobotino, 0, url1, vx, vy, om, Freq(i), i);
end
pause(t_parada);
for i = 1:10
    cancel(FutRob1{i});
end
%Vuelta
VelRob1 = [-0.18, 0.0, 0.0];
for i = 1:10
    vx = VelRob1(1);
    vy = VelRob1(2);
    om = VelRob1(3);
    FutRob1{i} = parfeval(@EnviarMovRobotino, 0, url1, vx, vy, om, Freq(i), i);
end
pause(t_parada);
for i = 1:10
    cancel(FutRob1{i});
end

%Mover a estación 2
moverCarro(0.3, 2.8, url3);

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

disp('>>>>>>>>>>>Rutina Robotino 2<<<<<<<<<<<<')
%Mover robotino 2
% Crear hilos en paralelo con parfeval para Robotino 2
%Ida
%Velocidades (Vx, Vy, Omega)
VelRob2 = [0.2, 0.0, 0.0];
for i = 1:10
    vx = VelRob2(1);
    vy = VelRob2(2);
    om = VelRob2(3);
    FutRob2{i} = parfeval(@EnviarMovRobotino, 0, url2, vx, vy, om, Freq(i), i);
end
pause(t_parada);
for i = 1:10
    cancel(FutRob2{i});
end
%Vuelta
VelRob2= [-0.18, 0.0, 0.0];
for i = 1:10
    vx = VelRob2(1);
    vy = VelRob2(2);
    om = VelRob2(3);
    FutRob2{i} = parfeval(@EnviarMovRobotino, 0, url2, vx, vy, om, Freq(i), i);
end
pause(t_parada);
for i = 1:10
    cancel(FutRob2{i});
end

%Mover a estación 1
moverCarro(-0.3, 2.8, url3);