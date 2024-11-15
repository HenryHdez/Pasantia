function moverCarro(velocidad, duracion, ipAddress)
    %Función para mover el carro
    %Positivo derecha
    %Negativo izquierda
    rosConectado = false;
    try
        %Si ros no esta conectado realiza la conexión
        rosnode list;
        rosConectado = true;
    catch
        disp('Iniciando conexión ROS...');
        rosinit(ipAddress);
    end
    
    % Crear el publicador para el comando de velocidad (cmd_vel)
    velPub = rospublisher('/cmd_vel', 'geometry_msgs/Twist');
    
    % Crear el mensaje de tipo Twist
    velMsg = rosmessage(velPub);
    
    % Definir la velocidad lateral en el eje Y (lateral en relación con el robot)
    velMsg.Linear.Y = velocidad;  % Velocidad positiva para moverse a la derecha, negativa para la izquierda
    
    % Enviar el comando de velocidad
    send(velPub, velMsg);
    disp('Moviendo de izquierda a derecha...');
    
    % Pausar durante el tiempo especificado
    pause(duracion);
    
    % Detener el robot (poner todas las velocidades a cero)
    velMsg.Linear.X = 0;
    velMsg.Linear.Y = 0;
    velMsg.Linear.Z = 0;
    velMsg.Angular.X = 0;
    velMsg.Angular.Y = 0;
    velMsg.Angular.Z = 0;
    
    % Enviar el comando para detener el robot
    send(velPub, velMsg);

    %Terminar ROS
    if ~rosConectado
        disp('Cerrando conexión ROS...');
        rosshutdown;
    end

end
