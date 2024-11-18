function moverCarro(velocidadX, velocidadY, velocidadTheta)
    % Función para mover el carro en los ejes X, Y y Theta
    % velocidadX: velocidad en el eje X (frontal o traslacional)
    % velocidadY: velocidad en el eje Y (lateral)
    % velocidadTheta: velocidad angular alrededor del eje Z (rotación)
    % Crear el publicador para el comando de velocidad (cmd_vel)
    velPub = rospublisher('/cmd_vel', 'geometry_msgs/Twist');
    if isempty(velPub)
        error('No se pudo crear el publicador /cmd_vel');
    end
    velMsg = rosmessage(velPub);
    % Asignar velocidades a los ejes X, Y y Theta
    velMsg.Linear.X = velocidadX;   
    velMsg.Linear.Y = velocidadY;   
    velMsg.Linear.Z = 0;            
    velMsg.Angular.Z = velocidadTheta; 
    % Enviar el comando de velocidad
    send(velPub, velMsg);
end
