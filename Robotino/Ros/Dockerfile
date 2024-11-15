# Usa la imagen base de ROS Noetic
FROM ros:noetic-ros-core

# Instala Python, rospy, curl y utilidades de red
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-rospy \
    iputils-ping \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configura el entorno
#ENV ROS_MASTER_URI=http://192.168.176.92:11311
#ENV ROS_IP=192.168.176.92
ENV ROS_MASTER_URI=http://192.168.1.100:11311
ENV ROS_IP=192.168.1.100

# Copia el script Python a la imagen
COPY listener.py /root/listener.py

# Establece el directorio de trabajo
WORKDIR /root

# Fuente el entorno de ROS
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

# Comando por defecto para ejecutar el script
CMD ["python3", "/root/listener.py"]
