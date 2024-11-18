function Soltarelemento(ipAddress, tiempopar)  
    ipAddress='192.168.1.150'; %IP del KuKa
    % Establecer conexión mediante ROS con el Robot Kuka
    rosConectado = false;
    try
        rosnode list;
        rosConectado = true;
    catch
        disp('Iniciando conexión ROS...');
        rosinit(ipAddress);
    end
    %%>>>>>>>>>>>>>>>Rutina de operación del KuKa<<<<<<<<<<<<<<<<<<<<<<<<
    % Crear el publicador para el gripper
    gripperPub = rospublisher(...
        '/arm_1/gripper_controller/position_command', ...
        'brics_actuator/JointPositions');
    abrirGripper(gripperPub);
    pause(5); % Espere 5 segundos
    cerrarGripper(gripperPub);
    pause(5);
    %%>>>>>>>>>>> Fin Rutina de operación del KuKa<<<<<<<<<<<<<<<<<<<<<<<<
    % Desconectar si termina el SCRIPT
    if ~rosConectado
        disp('Cerrando conexión ROS...');
        rosshutdown;
    end
end

