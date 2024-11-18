function moverBrazo(targetPositions, numIntermedios, ipAddress)
    %Funcion para estimar la trayectoria del brazo robótico
    rosConectado = false;
    try
        %Si ros no esta conectado realiza la conexión
        rosnode list;
        rosConectado = true;
    catch
        disp('Iniciando conexión ROS...');
        rosinit(ipAddress);
    end

    % Publicador de trayectorias del brazo
    armTrajPub = rospublisher('/arm_1/arm_controller/follow_joint_trajectory/goal', 'control_msgs/FollowJointTrajectoryActionGoal');
    % Crear mensaje
    armTrajMsg = rosmessage(armTrajPub);
    armTrajMsg.Goal.Trajectory.JointNames = {'arm_joint_1', 'arm_joint_2', 'arm_joint_3', 'arm_joint_4', 'arm_joint_5'};
    jointStateSub = rossubscriber('/joint_states', 'sensor_msgs/JointState');
    
    % Leer la posición actual del robot
    jointStateMsg = receive(jointStateSub, 10);
    currentPositions = jointStateMsg.Position(1:5);

    % Calcular puntos intermedios entre el origen y el destino
    puntosIntermedios = zeros(numIntermedios, 5);
    for i = 1:5
        rango = linspace(currentPositions(i), targetPositions(i), numIntermedios + 1);
        puntosIntermedios(:, i) = rango(2:end);
    end

    %Baja velocidad y aceleración
    velocities = [0.001, 0.001, 0.001, 0.001, 0];
    accelerations = [0.001, 0.001, 0.001, 0.001, 0.001];

    % Mover a traves de los puntos intermedios
    for punto = 1:numIntermedios
        armPoint = rosmessage('trajectory_msgs/JointTrajectoryPoint');
        armPoint.Positions = puntosIntermedios(punto, :);
        armPoint.Velocities = velocities;
        armPoint.Accelerations = accelerations;
        armPoint.TimeFromStart = rosduration(0.1);
        armTrajMsg.Goal.Trajectory.Points = armPoint;
        send(armTrajPub, armTrajMsg);
        pause(0.32);
    end

    if ~rosConectado
        disp('Cerrando conexión ROS...');
        rosshutdown;
    end
end
