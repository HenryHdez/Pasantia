%%%Control de los robots usando hilos
%Parar todos los hilos
%delete(gcp('nocreate'));

function principal()

    ip1 = '192.168.1.101'; % Robotino 1
    

    timer1 = timer('StartDelay', 0, 'Period', 0.3, ...
                   'ExecutionMode', 'fixedRate', ...
                   'TimerFcn', @(~,~) enviarDatosRob2('192.168.1.107', 1));  % Temporizador 1
               
    timer2 = timer('StartDelay', 0.5, 'Period', 0.2, ...
                   'ExecutionMode', 'fixedRate', ...
                   'TimerFcn', @(~,~) enviarDatosRob2('192.168.1.107', 2));  % Temporizador 2

    start(timer1);
    start(timer2);

    pause(10);  % Tiempo que se ejecutan los temporizadores

    % Después de detenerlos, los eliminamos
    if isvalid(timer1)
        delete(timer1);
        disp('Temporizador 1 eliminado.');
    end

    if isvalid(timer2)
        delete(timer2);
        disp('Temporizador 2 eliminado.');
    end

    %result3 = fetchOutputs(R3);

end

% Función para controlar al robot KuKa
function out = KuKactuadors()
    global PararRueRob2;
    ip = '192.168.1.102';
    rosshutdown;
    rosinit(ip);
    
    gripperPub = rospublisher('/arm_1/gripper_controller/position_command', ...
        'brics_actuator/JointPositions');
    
    abrirGripper(gripperPub);
    % Mover al punto de tomar muestra
    moverBrazo([2.8, 0.3, -3, 0.42, 0], 15, ip);
    cerrarGripper(gripperPub);
    moverBrazo([0.5, 0.5, -0.5, 0.5, 0], 15, ip);
    
    rosshutdown;
    out = 1;
    disp(dim(PararRueRob2))
end

% Función que simula el envío de datos
function enviarDatosRob2(ip, i)
    url = strcat('http://', ip, '/data/omnidrive');
    VelRob1 = [0.25, 0.0, 0.0];
    vx = VelRob1(1);
    vy = VelRob1(2);
    om = VelRob1(3);
    try
        webwrite(url, [vx, vy, om]);
        disp(['Datos enviados desde temporizador ', num2str(i), ' con Vx=', num2str(vx), ' Vy=', num2str(vy), ' Omega=', num2str(om)]);
    catch ME
        disp(['Error al enviar datos desde temporizador : ', ME.message]);
    end
end