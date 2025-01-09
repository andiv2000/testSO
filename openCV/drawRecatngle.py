import cv2

# Load the image
image = cv2.imread('road.jpg')

# Check if the image was loaded successfully
if image is None:
    print("Error: Image could not be loaded. Check the file path or format.")
else:
    # Copy the original image
    output = image.copy()

    # Define rectangle coordinates
    start_point = (100, 500)  # Top-left corner of the rectangle
    end_point = (600, 400)    # Bottom-right corner of the rectangle
    color = (255, 0, 0)       # Color of the rectangle (Blue in BGR format)
    thickness = 2             # Thickness of the rectangle border

    # Draw the rectangle
    cv2.rectangle(output, start_point, end_point, color, thickness)

    # Display the image with the rectangle
    cv2.imshow("Image with Rectangle", output)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
