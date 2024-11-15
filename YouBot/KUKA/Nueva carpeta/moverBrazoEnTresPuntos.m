function moverBrazoEnTresPuntos(targetPositions, numIntermedios, ipAddress)
    % moverBrazoEnTresPuntos - Lee la posición actual, divide el rango en tres puntos
    % y mueve el brazo lentamente a través de esos puntos
    % targetPositions: Vector con las posiciones objetivo para las 5 articulaciones
    % ipAddress: Dirección IP del KUKA YouBot

    % Verificar si ROS ya está iniciado
    rosConectado = false;
    try
        % Si `rosnode list` no lanza error, ROS está conectado
        rosnode list;
        rosConectado = true;
    catch
        % Si hay un error, ROS no está conectado, iniciarlo
        disp('Iniciando conexión ROS...');
        rosinit(ipAddress);
    end

    % Crear el publicador para el controlador de trayectorias del brazo
    armTrajPub = rospublisher('/arm_1/arm_controller/follow_joint_trajectory/goal', 'control_msgs/FollowJointTrajectoryActionGoal');

    % Crear el mensaje de tipo FollowJointTrajectoryActionGoal
    armTrajMsg = rosmessage(armTrajPub);

    % Definir los nombres de las articulaciones del brazo
    armTrajMsg.Goal.Trajectory.JointNames = {'arm_joint_1', 'arm_joint_2', 'arm_joint_3', 'arm_joint_4', 'arm_joint_5'};

    % Obtener la posición actual del robot
    jointStateSub = rossubscriber('/joint_states', 'sensor_msgs/JointState');
    
    % Leer la posición actual del robot
    jointStateMsg = receive(jointStateSub, 10);  % Espera hasta 10 segundos para recibir un mensaje
    currentPositions = jointStateMsg.Position(1:5);  % Obtener las posiciones actuales de las primeras 5 articulaciones

    % Dividir el rango en tres puntos intermedios
    puntosIntermedios = zeros(numIntermedios, 5);

    for i = 1:5
        % Calcular los puntos intermedios entre la posición actual y la posición objetivo
        rango = linspace(currentPositions(i), targetPositions(i), numIntermedios + 1);
        puntosIntermedios(:, i) = rango(2:end);  % Los puntos intermedios sin incluir la posición inicial
    end

    % Preparar las velocidades y aceleraciones lentas
    velocities = [0.001, 0.001, 0.001, 0.001, 0];  % Velocidades muy lentas
    accelerations = [0.001, 0.001, 0.001, 0.001, 0.001];  % Aceleraciones suaves

    % Mover a través de los puntos intermedios
    for punto = 1:numIntermedios
        % Crear un punto de trayectoria
        armPoint = rosmessage('trajectory_msgs/JointTrajectoryPoint');
        armPoint.Positions = puntosIntermedios(punto, :);
        armPoint.Velocities = velocities;
        armPoint.Accelerations = accelerations;
        armPoint.TimeFromStart = rosduration(0.1);  % Movimiento lento de 5 segundos por punto

        % Asignar el punto de trayectoria al mensaje
        armTrajMsg.Goal.Trajectory.Points = armPoint;

        % Enviar el comando de trayectoria
        send(armTrajPub, armTrajMsg);

        % Pausar para permitir que el movimiento ocurra
        pause(0.32);  % Pausa de 5 segundos para permitir que se complete el movimiento
    end

    disp('El brazo ha alcanzado el punto objetivo a través de los puntos intermedios.');

    % Cerrar la conexión con ROS solo si fue iniciada por la función
    if ~rosConectado
        disp('Cerrando conexión ROS...');
        rosshutdown;
    end
end
