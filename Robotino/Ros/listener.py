import rospy
from std_msgs.msg import String

def callback(data):
    rospy.loginfo(rospy.get_caller_id() + " I heard %s", data.data)

def listener():
    # Inicializa el nodo de ROS
    rospy.init_node('listener', anonymous=True)

    # Suscribirse al tópico /chatter
    rospy.Subscriber('/chatter', String, callback)

    # Mantiene el nodo vivo
    rospy.spin()

if __name__ == '__main__':
    listener()
