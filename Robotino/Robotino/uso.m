vx = -1.0;
vy = 1.0;
omega = 0.0;
response = robotinoAPI('http://192.168.1.100', 'GET', '/data/charger1', []);
disp(response);