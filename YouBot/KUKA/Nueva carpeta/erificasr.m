clear all;
rosshutdown;  % Cierra cualquier conexión previa

% Configura la IP del nodo maestro de ROS (reemplaza con la IP del YouBot)
ipAddress = '192.168.28.201';  % Cambia esta IP si es necesario
rosinit(ipAddress);  % Inicia la conexión con ROS

jointStateSub = rossubscriber('/joint_states', 'sensor_msgs/JointState');

%rosoutSub = rossubscriber('/rosout', 'rosgraph_msgs/Log');
%rosoutMsg = receive(rosoutSub, 10);
disp('Mensaje de /rosout:');
disp(jointStateSub.LatestMessage);
