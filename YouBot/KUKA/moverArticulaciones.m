function moverArticulaciones(targetPositions, targetVel, time, ipAddress)
    % ROS Conexión
    rosConectado = false;
    try
        rosnode list;
        rosConectado = true;
    catch
        disp('Iniciando conexión ROS...');
        rosinit(ipAddress);
    end

    % Crear el publicador
    armTrajPub = rospublisher('/arm_1/arm_controller/follow_joint_trajectory/goal', 'control_msgs/FollowJointTrajectoryActionGoal');
    armTrajMsg = rosmessage(armTrajPub);
    armTrajMsg.Goal.Trajectory.JointNames = {'arm_joint_1', 'arm_joint_2', 'arm_joint_3', 'arm_joint_4', 'arm_joint_5'};
    jointStateSub = rossubscriber('/joint_states', 'sensor_msgs/JointState');
    numMovimientos = size(targetPositions, 1);

    for movimiento = 1:numMovimientos
        % Obtener la posición objetivo y velocidad para este movimiento
        targetPos = targetPositions(movimiento, :);
        velocities = targetVel(movimiento, :);
        currentAccelerations = [0.2, 0.2, 0.2, 0.2, 0.2];
        %Verifica si los puntos de las articulaciones estan en la posicion
        %final
        reachedTarget = [false, false, false, false, false];

        % Algoritmo de busqueda
        while ~all(reachedTarget)  
            totalPositions = zeros(5, 1);  
            numLecturas = 5; 
            %Promedio del valor de las lecturas
            for lectura = 1:numLecturas
                jointStateMsg = receive(jointStateSub, 10);
                currentPositions = jointStateMsg.Position(1:5);
                totalPositions = totalPositions + currentPositions;
                pause(0.01);
            end
            averagePositions = totalPositions.*(1/numLecturas);
            
            % Crear un punto de trayectoria con las posiciones promedio
            armPoint = rosmessage('trajectory_msgs/JointTrajectoryPoint');
            armPoint.Positions = averagePositions;
            currentPositions = averagePositions;
            %disp(currentPositions)
            currentVelocities = velocities;  % Usar las velocidades originales
            
            % Revisar cada articulación
            for i = 1:5
                % Calcular el error absoluto entre la posición actual y la posición objetivo
                %fprintf('Movimiento >>>>>>>>> %d <<<<<<<\n', movimiento);
                error = abs(currentPositions(i) - targetPos(i)) / 4*pi * 100;
                %fprintf('Error en la articulación %d: %f\n', i, error);
                %fprintf('Posición actual de la articulación %d: %f\n', i, currentPositions(i));
                %disp(averagePositions)
                if error < 10  
                    reachedTarget(i) = true;
                    %currentVelocities(i) = 0;  % Poner velocidad en cero
                    currentAccelerations(i) = 0;  % Poner aceleración en cero
                    %fprintf('La articulación %d ha alcanzado la posición objetivo.\n', i);
                else
                    if currentPositions(i) < targetPos(i)
                        currentPositions(i) = currentPositions(i) + 0.1;
                    else
                        currentPositions(i) = currentPositions(i) - 0.1;
                    end
                end
            end
            %mensaje de salida
            armPoint.Positions = currentPositions;
            armPoint.Velocities = currentVelocities;
            armPoint.Accelerations = currentAccelerations;
            armPoint.TimeFromStart = rosduration(time(movimiento)); 
            armTrajMsg.Goal.Trajectory.Points = armPoint;
            send(armTrajPub, armTrajMsg);
        end
        %disp(['Movimiento ', num2str(movimiento), ' completado.']);
    end
    %Terminar ROS
    if ~rosConectado
        disp('Cerrando conexión ROS...');
        rosshutdown;
    end
end