import cv2
image=cv2.imread('road.jpg')
output=image.copy()

text=cv2.putText(output, 'Hello World!', (500,500), 
cv2.FONT_HERSHEY_SIMPLEX,4,(255,0,0),2)