url1 = 'http://192.168.128.92/data/omnidrive';  % Robotino 1
url2 = 'http://192.168.128.199/data/omnidrive';   % Robotino 2
url3 = '192.168.128.192';   % KukaBot

moverCarro(0.3, 1, url3);
% Velocidad de cada robotino
VelRob1 = [0.2, 0.0, 0.0];
VelRob2 = [0.2, 0.0, 0.0];
%Frecuencia de actualización
Freq = 0:100:1000;

%Vector que almacenara los hilos de cada robot
FutRob1 = cell(1, 6);
FutRob2 = cell(1, 6);

% Crear hilos en paralelo con parfeval para Robotino 1
for i = 1:10
    vx = VelRob1(1);
    vy = VelRob1(2);
    om = VelRob1(3);
    FutRob1{i} = parfeval(@EnviarMovRobotino, 0, url1, vx, vy, om, Freq(i), i);
    vx = VelRob2(1);
    vy = VelRob2(2);
    om = VelRob2(3);
    FutRob2{i} = parfeval(@EnviarMovRobotino, 0, url2, vx, vy, om, Freq(i), i);
end

% Ejecutar los hilos durante 15 segundos
pause(10);

% Cancelar los futuros (detener los hilos)
for i = 1:10
    cancel(FutRob1{i});
    cancel(FutRob2{i});
    disp(['Hilo ', num2str(i), ' detenido']);
end
