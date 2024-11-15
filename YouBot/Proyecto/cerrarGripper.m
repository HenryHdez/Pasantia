function cerrarGripper(gripperPub)
    gripperMsg = rosmessage(gripperPub);
    % Crear dos posiciones para los dos dedos del gripper
    fingerL = rosmessage('brics_actuator/JointValue');
    fingerR = rosmessage('brics_actuator/JointValue');
    % Definir los nombres de las articulaciones del gripper
    fingerL.JointUri = 'gripper_finger_joint_l';
    fingerR.JointUri = 'gripper_finger_joint_r';
    % Asignar posiciones para cerrar el gripper
    fingerL.Value = 0.0;  % Cerrar la articulación izquierda
    fingerR.Value = 0.0;  % Cerrar la articulación derecha
    % Especificar la unidad de medida (metros)
    fingerL.Unit = 'm';
    fingerR.Unit = 'm';
    % Asignar las posiciones al mensaje
    gripperMsg.PoisonStamp = rosmessage('brics_actuator/Poison'); 
    gripperMsg.Positions = [fingerL, fingerR];
    % Enviar el comando para cerrar el gripper
    send(gripperPub, gripperMsg);
end
