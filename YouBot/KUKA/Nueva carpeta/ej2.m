clc;
clear all;
rosshutdown;  % Cierra cualquier conexión previa

% Configura la IP del nodo maestro de ROS (cambia esta IP si es necesario)
ipAddress = '192.168.243.170';  % IP del KUKA YouBot
rosinit(ipAddress);  % Inicia la conexión con ROS

% Verificar si MATLAB está conectado al nodo ROS
try
    rosnode list
    disp('Conexión con ROS exitosa.');
catch
    error('No se pudo conectar a ROS. Verifica ROS_MASTER_URI y la conexión de red.');
end

% Suscribirse al tópico /joint_states
jointStateSub = rossubscriber('/joint_states', 'sensor_msgs/JointState');

% Aumentar el tiempo de espera para recibir el mensaje
disp('Esperando recibir datos de /joint_states...');
try
    jointStateMsg = receive(jointStateSub, 5);  % Espera hasta 30 segundos para recibir un mensaje
    
    % Extraer las velocidades actuales de las articulaciones
    jointVelocities = jointStateMsg.Position;
    
    % Verificar si se recibieron velocidades
    if isempty(jointVelocities)
        disp('No se recibieron datos de velocidad. Asegúrate de que el robot esté publicando estos datos.');
    else
        disp('Velocidades actuales de las articulaciones (radianes/segundo):');
        disp(jointVelocities);
    end
catch
    error('No se recibieron datos de /joint_states. Verifica si el tópico está activo y publicando.');
end

% Cerrar la conexión con ROS
rosshutdown;
