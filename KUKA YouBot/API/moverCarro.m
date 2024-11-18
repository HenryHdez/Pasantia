function moverCarro(velocidadX, velocidadY, velocidadTheta, ipAddress, tiempoEjecucion)
    % Publicador para enviar comandos de velocidad
    velPub = rospublisher('/cmd_vel', 'geometry_msgs/Twist');
    velMsg = rosmessage(velPub);

    % Asignar velocidades
    velMsg.Linear.X = velocidadX;
    velMsg.Linear.Y = velocidadY;
    velMsg.Linear.Z = 0; % No hay velocidad en Z
    velMsg.Angular.Z = velocidadTheta;

    % Enviar mensaje
    send(velPub, velMsg);

    % Mantener movimiento durante el tiempo especificado
    pause(tiempoEjecucion);

    % Detener movimiento
    velMsg.Linear.X = 0;
    velMsg.Linear.Y = 0;
    velMsg.Angular.Z = 0;
    send(velPub, velMsg);
end
