function moverCarro(velocidadX, velocidadY, velocidadTheta, duracion, ipAddress)
    % Función para mover el carro en los ejes X, Y y Theta
    % velocidadX: velocidad en el eje X (frontal o traslacional)
    % velocidadY: velocidad en el eje Y (lateral)
    % velocidadTheta: velocidad angular alrededor del eje Z (rotación)
    % duracion: duración del movimiento en segundos
    % ipAddress: dirección IP para conectar ROS



    % Crear el publicador para el comando de velocidad (cmd_vel)
    velPub = rospublisher('/cmd_vel', 'geometry_msgs/Twist');
    
    % Verificar que el publicador esté correctamente creado
    if isempty(velPub)
        error('No se pudo crear el publicador /cmd_vel');
    end

    % Crear el mensaje de tipo Twist
    velMsg = rosmessage(velPub);
    
    % Asignar velocidades a los ejes X, Y y Theta
    velMsg.Linear.X = velocidadX;   % Movimiento hacia adelante/atrás en X
    velMsg.Linear.Y = velocidadY;   % Movimiento lateral en Y
    velMsg.Linear.Z = 0;            % Mantener el eje Z en cero (sin desplazamiento vertical)
    velMsg.Angular.Z = velocidadTheta; % Rotación en torno al eje Z
    
    % Enviar el comando de velocidad
    send(velPub, velMsg);
    disp('Moviendo el robot en X, Y y Theta...');
    
    % Pausar durante el tiempo especificado
    % pause(duracion);
    % 
    % % Detener el robot al poner todas las velocidades a cero
    % velMsg.Linear.X = 0;
    % velMsg.Linear.Y = 0;
    % velMsg.Linear.Z = 0;
    % velMsg.Angular.X = 0;
    % velMsg.Angular.Y = 0;
    % velMsg.Angular.Z = 0;
    % 
    % % Enviar el comando para detener el robot
    % send(velPub, velMsg);
    % 
    % % Cerrar conexión ROS
    % disp('Cerrando conexión ROS...');
    % rosshutdown;
end
