function enviarMovimientoBrazo(positions, velocities, accelerations, times, ipAddress)
    % Función para enviar movimientos al KUKA YouBot, un punto de trayectoria por iteración
    % positions: Matriz NxM, donde N es el número de movimientos y M el número de articulaciones
    % velocities: Matriz NxM de velocidades
    % accelerations: Matriz NxM de aceleraciones
    % times: Vector Nx1 de tiempos en segundos para cada movimiento
    % ipAddress: Dirección IP del nodo maestro de ROS (robot)
    rosConectado = false;
    try
        % Si `rosnode list` no lanza error, ROS está conectado
        rosnode list;
        rosConectado = true;
    catch
        rosshutdown;
        % Si hay un error, ROS no está conectado, iniciarlo
        disp('Iniciando conexión ROS...');
        rosinit(ipAddress);
    end

    % Verificar que las dimensiones de los parámetros coincidan
    if size(positions, 1) ~= length(times) || size(positions, 2) ~= 5
        error('Las dimensiones de las posiciones no coinciden con los tiempos o con el número de articulaciones (5).');
    end

    if size(velocities, 1) ~= size(positions, 1) || size(velocities, 2) ~= 5
        error('Las dimensiones de las velocidades no coinciden con las posiciones.');
    end

    if size(accelerations, 1) ~= size(positions, 1) || size(accelerations, 2) ~= 5
        error('Las dimensiones de las aceleraciones no coinciden con las posiciones.');
    end

    % Cerrar cualquier conexión ROS previa
    %rosshutdown;

    % Iniciar la conexión con el nodo maestro de ROS
    %rosinit(ipAddress);

    % Crear el publicador para el controlador de trayectorias del brazo
    armTrajPub = rospublisher('/arm_1/arm_controller/follow_joint_trajectory/goal', 'control_msgs/FollowJointTrajectoryActionGoal');

    % Crear el mensaje de tipo FollowJointTrajectoryActionGoal
    armTrajMsg = rosmessage(armTrajPub);

    % Definir los nombres de las articulaciones del brazo
    armTrajMsg.Goal.Trajectory.JointNames = {'arm_joint_1', 'arm_joint_2', 'arm_joint_3', 'arm_joint_4', 'arm_joint_5'};

    % Crear los puntos de la trayectoria, uno por iteración
    numMovimientos = size(positions, 1);

    for i = 1:numMovimientos
        % Crear un punto de trayectoria
        armPoint = rosmessage('trajectory_msgs/JointTrajectoryPoint');
        
        % Asignar posiciones, velocidades, y aceleraciones
        armPoint.Positions = positions(i, :);
        armPoint.Velocities = velocities(i, :);
        armPoint.Accelerations = accelerations(i, :);
        
        % Asignar el tiempo para alcanzar esta posición
        armPoint.TimeFromStart = rosduration(times(i));

        % Asignar el único punto de trayectoria al mensaje
        armTrajMsg.Goal.Trajectory.Points = armPoint;

        % Enviar el comando de trayectoria al brazo
        send(armTrajPub, armTrajMsg);

        % Imprimir confirmación
        disp(['Comando de trayectoria ', num2str(i), ' enviado al brazo del KUKA YouBot.']);

        % Pausar para permitir que el robot complete el movimiento antes del siguiente
        pause(times(i) + 1);  % Tiempo de pausa para asegurar que el movimiento se complete
    end

    % Cerrar la conexión con ROS después de enviar todos los movimientos
    % Cerrar la conexión con ROS solo si fue iniciada por la función
    if ~rosConectado
        disp('Cerrando conexión ROS...');
        rosshutdown;
    end

    disp('Todos los movimientos han sido enviados y completados.');
end
