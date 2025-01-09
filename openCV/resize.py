import cv2
image=cv2.imread('poza.jpg')

pozaModificata=cv2.resize(image,(250,250))

cv2.imshow("Image with Rectangle", pozaModificata)
cv2.waitKey(0)

print("Nice")

for i in range(1,10):
    