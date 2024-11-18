function abrirGripper(gripperPub)
    gripperMsg = rosmessage(gripperPub);
    % Crear dos posiciones para los dos dedos del gripper
    fingerL = rosmessage('brics_actuator/JointValue');
    fingerR = rosmessage('brics_actuator/JointValue');
    % Definir los nombres de las articulaciones del gripper
    fingerL.JointUri = 'gripper_finger_joint_l';
    fingerR.JointUri = 'gripper_finger_joint_r';
    % Asignar posiciones para abrir el gripper
    fingerL.Value = 0.0115;  % Abrir la articulación izquierda
    fingerR.Value = 0.0115;  % Abrir la articulación derecha
    % Especificar la unidad de medida (metros)
    fingerL.Unit = 'm';
    fingerR.Unit = 'm';
    % Asignar las posiciones al mensaje
    gripperMsg.PoisonStamp = rosmessage('brics_actuator/Poison');  
    gripperMsg.Positions = [fingerL, fingerR];
    % Enviar el comando para abrir el grippe
    send(gripperPub, gripperMsg);
end