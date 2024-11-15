import rospy
from std_msgs.msg import String

# Callback function to process the received message
def callback(msg):
    rospy.loginfo("Mensaje recibido: %s", msg.data)

# Inicializar el nodo ROS
rospy.init_node('listener', anonymous=True)

# Suscribirse al tópico /chatter
chatter_sub = rospy.Subscriber('/chatter', String, callback)

# Mantener el nodo corriendo hasta que se detenga con Ctrl+C
rospy.spin()

# No es necesario llamar a rospy.shutdown() explícitamente
