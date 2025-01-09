import cv2

# Load the image
image = cv2.imread('poza.jpg')

# Check if the image was loaded successfully
if image is None:
    print("Error: Image could not be loaded. Check the file path or format.")
else:
    # Calculate the region of interest (ROI)
    # Slicing pixels from row 100 to 500 and column 200 to 700
    roi = image[100:500, 200:700]
    
    # Display the ROI
    cv2.imshow("ROI", roi)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
