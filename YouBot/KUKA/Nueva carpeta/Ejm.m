clc;
clear all;
rosshutdown;  % Cierra cualquier conexión previa

% Configura la IP del nodo maestro de ROS (cambia esta IP si es necesario)
ipAddress = '192.168.243.45';  % IP del KUKA YouBot
rosinit(ipAddress);  % Inicia la conexión con ROS

% Crear el publicador para el controlador de trayectorias del brazo
armTrajPub = rospublisher('/arm_1/arm_controller/follow_joint_trajectory/goal', 'control_msgs/FollowJointTrajectoryActionGoal');

% Crear el mensaje de tipo FollowJointTrajectoryActionGoal
armTrajMsg = rosmessage(armTrajPub);

% Definir los nombres de las articulaciones del brazo
armTrajMsg.Goal.Trajectory.JointNames = {'arm_joint_1', 'arm_joint_2', 'arm_joint_3', 'arm_joint_4', 'arm_joint_5'};

% Definir tres movimientos con sus respectivas posiciones, velocidades y tiempos

% Movimiento 1: Posiciones iniciales
armPoint1 = rosmessage('trajectory_msgs/JointTrajectoryPoint');
armPoint1.Positions = [2, 0, 0.2, 0, 0];  % Posiciones objetivo para movimiento 1
armPoint1.Velocities = [0.1, 0, 0, 0, 0];  % Velocidades para movimiento 1
armPoint1.Accelerations = [0.01, 0, 0.5, 0, 0];  % Aceleraciones para movimiento 1
armPoint1.TimeFromStart = rosduration(5.0);  % Tiempo para completar el movimiento 1 (5 segundos)

% Movimiento 2: Siguiente conjunto de posiciones
armPoint2 = rosmessage('trajectory_msgs/JointTrajectoryPoint');
armPoint2.Positions = [1, 0.5, 0.5, 0, 0];  % Posiciones objetivo para movimiento 2
armPoint2.Velocities = [0.1, 0.1, 0, 0, 0];  % Velocidades para movimiento 2
armPoint2.Accelerations = [0.01, 0.01, 0.5, 0, 0];  % Aceleraciones para movimiento 2
armPoint2.TimeFromStart = rosduration(10.0);  % Tiempo total desde el inicio (10 segundos)

% Movimiento 3: Último conjunto de posiciones
armPoint3 = rosmessage('trajectory_msgs/JointTrajectoryPoint');
armPoint3.Positions = [0, 0.2, 0.1, 0, 0];  % Posiciones objetivo para movimiento 3
armPoint3.Velocities = [0.1, 0.05, 0, 0, 0];  % Velocidades para movimiento 3
armPoint3.Accelerations = [0.01, 0.01, 0.5, 0, 0];  % Aceleraciones para movimiento 3
armPoint3.TimeFromStart = rosduration(15.0);  % Tiempo total desde el inicio (15 segundos)

% Asignar los puntos de trayectoria al mensaje
armTrajMsg.Goal.Trajectory.Points = [armPoint1, armPoint2, armPoint3];

% Enviar el comando de trayectoria al brazo
send(armTrajPub, armTrajMsg);

% Imprimir confirmación
disp('Comando de trayectoria enviado al brazo del KUKA YouBot.');

% Esperar para que el brazo complete los movimientos
pause(20);  % Pausar lo suficiente para que el robot complete todos los movimientos

% Cerrar la conexión con ROS
rosshutdown;
