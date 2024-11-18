%Ejemplo 2 - Movilidad del robotino-
Vx = 0.3; %Velocidad en dirección del eje x >0 & <2
Vy = 0.0; %Velocidad en dirección del eje y >0 & <2
Om = 0.0; %Velocidad angular Omega >0 & <2
robotinoAPI('http://192.168.1.101', 'POST', ...
    '/data/omnidrive', [Vx, Vy, Om]);
