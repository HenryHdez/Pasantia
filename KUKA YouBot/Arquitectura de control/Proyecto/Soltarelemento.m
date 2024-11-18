function Soltarelemento(ipAddress, tiempopar)   
    % ROS Conexión
    rosConectado = false;
    try
        rosnode list;
        rosConectado = true;
    catch
        disp('Iniciando conexión ROS...');
        rosinit(ipAddress);
    end

    % Crear el publicador para el gripper
    gripperPub = rospublisher('/arm_1/gripper_controller/position_command', 'brics_actuator/JointPositions');
    abrirGripper(gripperPub);
    pause(tiempopar);
    cerrarGripper(gripperPub);
    pause(tiempopar);
    
    % ROS desconexión si fue iniciado en esta función
    if ~rosConectado
        disp('Cerrando conexión ROS...');
        rosshutdown;
    end
end