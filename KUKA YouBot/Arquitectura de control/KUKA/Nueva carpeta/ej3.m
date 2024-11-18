clc;
clear all;
rosshutdown;  % Cierra cualquier conexión previa

% Configura la IP del nodo maestro de ROS (reemplaza con la IP del YouBot)
ipAddress = '192.168.243.170';  % Cambia esta IP si es necesario
rosinit(ipAddress);  % Inicia la conexión con ROS

% Obtener la lista de tópicos disponibles
topics = rostopic('list');

% Verificar si el tópico del gripper está en la lista
if ~any(contains(topics, '/arm_1/gripper_controller/position_command'))
    error('El tópico /arm1/gripper_controller/position_command no está disponible. Verifica el nombre del tópico.');
end

% Crear el publicador para controlar las posiciones del gripper
gripperPub = rospublisher('/arm_1/gripper_controller/position_command', 'brics_actuator/JointPositions');

% Crear el mensaje de tipo JointPositions para el gripper
gripperMsg = rosmessage(gripperPub);

% Definir las propiedades del mensaje para mover el gripper
% Crear un JointValue para el gripper izquierdo
jointValueL = rosmessage('brics_actuator/JointValue');
jointValueL.JointUri = 'gripper_finger_joint_l';  % Nombre de la articulación izquierda
jointValueL.Unit = 'm';  % La unidad es metros (posiciones lineales)
jointValueL.Value = 0.0110;  % Ajusta el valor para abrir/cerrar el gripper

% Crear un JointValue para el gripper derecho
jointValueR = rosmessage('brics_actuator/JointValue');
jointValueR.JointUri = 'gripper_finger_joint_r';  % Nombre de la articulación derecha
jointValueR.Unit = 'm';
jointValueR.Value = 0.0110;  % Ajusta el valor para abrir/cerrar el gripper

% Asignar los valores de los dedos al mensaje
gripperMsg.PoisonStamp.Description = 'Gripper command';
gripperMsg.Positions = [jointValueL, jointValueR];

% Enviar el comando al gripper
send(gripperPub, gripperMsg);

% Imprimir confirmación
disp('Comando de posición enviado al gripper del KUKA YouBot.');

% Cerrar la conexión con ROS
rosshutdown;