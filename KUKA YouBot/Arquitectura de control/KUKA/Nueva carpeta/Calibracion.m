clc;
clear all;

rosshutdown;
% Definir la dirección IP del KUKA YouBot
ipAddress = '192.168.243.45';

% Iniciar la conexión con el nodo maestro de ROS
rosinit(ipAddress);  % Asegúrate de que la IP es la correcta

% Definir las posiciones de origen (punto inicial) para cada articulación
originPositions = [0.1, 0.1, 0.1, 0.1, 0.1];  % Todas las articulaciones a la posición "home"

% Definir las velocidades correspondientes para la calibración (extremadamente lentas)
velocities = [0.0001, 0.0001, 0.0001, 0.0001, 0.0001];  % Velocidades extremadamente bajas

% Definir las aceleraciones correspondientes para la calibración
accelerations = [0.0, 0.0, 0.0, 0.0, 0.0];  % Aceleraciones muy suaves

% Crear el publicador para el controlador de trayectorias del brazo
armTrajPub = rospublisher('/arm_1/arm_controller/follow_joint_trajectory/goal', 'control_msgs/FollowJointTrajectoryActionGoal');

% Crear el mensaje de tipo FollowJointTrajectoryActionGoal
armTrajMsg = rosmessage(armTrajPub);

% Definir los nombres de las articulaciones del brazo
armTrajMsg.Goal.Trajectory.JointNames = {'arm_joint_1', 'arm_joint_2', 'arm_joint_3', 'arm_joint_4', 'arm_joint_5'};

% Obtener la posición actual del robot
jointStateSub = rossubscriber('/joint_states', 'sensor_msgs/JointState');

% Mover las articulaciones una por una hasta el origen, monitoreando la posición
for i = 1:5
    % Crear un punto de trayectoria para la articulación actual
    armPoint = rosmessage('trajectory_msgs/JointTrajectoryPoint');

    % Mover solo la articulación 'i' hacia su posición de origen (cero)
    reachedZero = false;
    
    while ~reachedZero
        % Obtener la posición actual del robot
        jointStateMsg = receive(jointStateSub, 10);  % Espera hasta 10 segundos para recibir un mensaje
        currentPosition = jointStateMsg.Position(i);  % Obtener la posición de la articulación 'i'
        
        % Mostrar la posición actual de la articulación
        fprintf('Posición actual de la articulación %d: %f\n', i, currentPosition);
        
        % Verificar si la articulación ha alcanzado el cero
        if abs(currentPosition - originPositions(i)) < 0.1
            fprintf('La articulación %d ha alcanzado el origen.\n', i);
            reachedZero = true;  % Detener el movimiento para esta articulación
        else
            % Asignar una posición ligeramente más cercana al origen
            if currentPosition < 0 
                targetPosition = currentPosition + 0.01;  % Mover hacia el origen (0) de manera muy lenta
            else
                targetPosition = currentPosition - 0.01;
            end
            % Asignar la posición al punto de trayectoria
            targetPositions = jointStateMsg.Position(1:5);  % Mantener todas las posiciones actuales
            targetPositions(i) = targetPosition;  % Mover solo la articulación 'i'

            % Asignar la posición al mensaje
            armPoint.Positions = targetPositions;
            armPoint.Velocities = velocities;
            armPoint.Accelerations = accelerations;
            armPoint.TimeFromStart = rosduration(0.2);  % Tiempo extremadamente corto para hacer el movimiento lento

            % Enviar el comando de trayectoria
            armTrajMsg.Goal.Trajectory.Points = armPoint;
            send(armTrajPub, armTrajMsg);
            
            % Pausar brevemente para permitir que el movimiento ocurra
            pause(0.2);
        end
    end
end

disp('Calibración completada: todas las articulaciones han regresado al origen.');

% Cerrar la conexión con ROS
rosshutdown;
