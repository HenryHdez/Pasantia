function EnviarMovRobotino(url, vx, vy, omega, updateInterval, id)
    while true
        try
            webwrite(url, [vx, vy, omega]);
            pause(updateInterval / 1000);
        catch ME
            disp(['Error al enviar datos a Robotino en el hilo ', num2str(id), ':']);
            disp(ME.message);
            break;
        end
    end
end