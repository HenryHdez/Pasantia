%Leer variables del robotino
%robotinoAPI('http://IP', 'GET', '/cam0', []);
%robotinoAPI('http://IP', 'GET', '/sensorimage', []);
%robotinoAPI('http://IP', 'GET', '/data/powermanagement', []);
%robotinoAPI('http://IP', 'GET', '/data/charger0', []);
%robotinoAPI('http://IP', 'GET', '/data/charger1', []);
%robotinoAPI('http://IP', 'GET', '/data/controllerinfo', []);
%robotinoAPI('http://IP', 'GET', '/data/services', []);
%robotinoAPI('http://IP', 'GET', '/data/servicestatus/xxx', []);
%robotinoAPI('http://IP', 'GET', '/data/analoginputarray', []);
%robotinoAPI('http://IP', 'GET', '/data/digitalinputarray', []);
%robotinoAPI('http://IP', 'GET', '/data/digitaloutputstatus', []);
%robotinoAPI('http://192.168.1.100', 'GET', '/data/relaystatus', []);
%robotinoAPI('http://192.168.1.100', 'GET', '/data/bumper', []);
%robotinoAPI('http://192.168.1.100', 'GET', '/data/distancesensorarray', []);
%robotinoAPI('http://192.168.1.100', 'GET', '/data/scan0', []);
%robotinoAPI('http://192.168.1.100', 'GET', '/data/odometry', []);
%robotinoAPI('http://192.168.1.100', 'GET', '/data/imageversion', []);
%robotinoAPI('http://192.168.1.100', 'GET', '/data/poweroutputcurrent', []);
%Llame la función del API y acompañelo de la variable objetivo

%Estado de los sensores de proximidad
response = robotinoAPI('http://192.168.1.101', 'GET', ...
    '/data/distancesensorarray', []);
disp(response)
%Nivel de carga en las baterias 
response = robotinoAPI('http://192.168.1.101', 'GET', ...
    '/data/charger1', [])
%Configuración del odometro
response = robotinoAPI('http://192.168.1.101', 'GET', ...
    '/data/odometry', [])
disp(response)
%Lectura de la camára
response2 = robotinoAPI('http://192.168.1.101', 'GET', '/cam0', []);
imshow(response2)
