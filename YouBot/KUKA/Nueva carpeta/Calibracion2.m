clc;
clear;
rosshutdown;

% Definir la dirección IP del KUKA YouBot
ipAddress = '192.168.243.45';

% Iniciar la conexión con el nodo maestro de ROS
rosinit(ipAddress);  % Asegúrate de que la IP es la correcta

% Definir las posiciones de origen (punto inicial) para cada articulación
originPositions = [0, 0, 0, 0, 0];  % Todas las articulaciones a la posición "home"

% Definir las velocidades y aceleraciones extremadamente lentas
velocities = [0.005, 0.005, 0.005, 0.005, 0.005];  % Velocidades bajas
accelerations = [0.0, 0.0, 0.0, 0.0, 0.0];  % Aceleraciones suaves
targetPositions = originPositions;
% Crear el publicador para el controlador de trayectorias del brazo
armTrajPub = rospublisher('/arm_1/arm_controller/follow_joint_trajectory/goal', 'control_msgs/FollowJointTrajectoryActionGoal');

% Crear el mensaje de tipo FollowJointTrajectoryActionGoal
armTrajMsg = rosmessage(armTrajPub);

% Definir los nombres de las articulaciones del brazo
armTrajMsg.Goal.Trajectory.JointNames = {'arm_joint_1', 'arm_joint_2', 'arm_joint_3', 'arm_joint_4', 'arm_joint_5'};

% Obtener la posición actual del robot
jointStateSub = rossubscriber('/joint_states', 'sensor_msgs/JointState');

% Inicializar una bandera para cada articulación que indica si ha alcanzado la posición cero
reachedZero = [false, false, false, false, false];

% Mover las articulaciones una por una hasta el origen, monitoreando la posición
while ~all(reachedZero)  % Continuar hasta que todas las articulaciones hayan llegado a cero
    % Obtener la posición actual del robot
    jointStateMsg = receive(jointStateSub, 10);  % Espera hasta 10 segundos para recibir un mensaje
    currentPositions = jointStateMsg.Position(1:5);  % Obtener las posiciones actuales de las primeras 5 articulaciones

    % Crear un punto de trayectoria
    armPoint = rosmessage('trajectory_msgs/JointTrajectoryPoint');
    
    % Preparar las velocidades y aceleraciones para cada articulación
    currentVelocities = velocities;       % Usar las velocidades originales
    currentAccelerations = accelerations; % Usar las aceleraciones originales
    
    % Revisar cada articulación
    for i = 1:5
        % Calcular el porcentaje de error entre la posición actual y la posición del sensor
        error = abs(currentPositions(i) - originPositions(i)) / 4*pi * 100;
        fprintf('Error porcentual en la articulación %d: %f%%\n', i, error);
        fprintf('Posición actual de la articulación %d: %f\n', i, currentPositions(i));
        if error < 10
            % Si la articulación ha alcanzado el origen, detenerla
            reachedZero(i) = true;
            currentVelocities(i) = 0;  % Poner velocidad en cero
            currentAccelerations(i) = 0;  % Poner aceleración en cero
            fprintf('La articulación %d ha alcanzado el origen.\n', i);
        elseif (error >= 10 && reachedZero(i) == false)
            % Asignar una posición ligeramente más cercana al origen
            if currentPositions(i) <= 0
                targetPositions(i) = currentPositions(i) + 0.05;  % Mover hacia el origen (0) de manera muy lenta
            else
                targetPositions(i) = currentPositions(i) - 0.05;
            end
        end
    end

    % Asignar las posiciones y velocidades al mensaje de trayectoria
    armPoint.Positions = targetPositions;
    armPoint.Velocities = currentVelocities;
    armPoint.Accelerations = currentAccelerations;
    armPoint.TimeFromStart = rosduration(0.1);  % Movimiento extremadamente lento

    % Asignar el punto de trayectoria al mensaje
    armTrajMsg.Goal.Trajectory.Points = armPoint;

    % Enviar el comando de trayectoria
    send(armTrajPub, armTrajMsg);

    % Pausar brevemente para permitir que el movimiento ocurra
    pause(0.5);
end

disp('Calibración completada: todas las articulaciones han regresado al origen.');

% Cerrar la conexión con ROS
rosshutdown;
