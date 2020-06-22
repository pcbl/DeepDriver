# -*- coding: utf-8 -*-
"""
Created on Sun Jun 21 23:02:02 2020

@author: polg
"""

import cv2
import numpy as np
import matplotlib.pyplot as plt


def canny(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5,5), 0)
    canny = cv2.Canny(blur,50,150)
    return canny

def display_lines(image, lines):
    line_image = np.zeros_like(image)
    if lines is not None:
        for x1, y1, x2, y2 in lines:           
           cv2.line(line_image, (x1,y1), (x2,y2), (255,0,0), 10)
    return line_image

def make_coordinates(image,line_parameters):
    slope, intercept = line_parameters
    y1 = image.shape[0]
    y2 = int(y1 * 3 / 5)
    x1 = int((y1 - intercept)/slope)
    x2 = int((y2 - intercept)/slope)
    return np.array([x1,y1,x2,y2])   

def average_slope_intercept(image, lines):
    left_fit = []
    right_fit = []
    for line in lines:
        x1, y1, x2, y2 = line.reshape(4)
        parameters = np.polyfit((x1,x2),(y1,y2),1)
        slope = parameters[0]
        intercept = parameters[1]
        if slope < 0:
            left_fit.append((slope,intercept))
        else:
            right_fit.append((slope,intercept))            
    averaged_lines = []
    
    if len(left_fit):
        left_fit_average = np.average(left_fit, axis=0)
        left_line = make_coordinates(image, left_fit_average)
        averaged_lines.append(left_line)
    
    if len(right_fit):        
        right_fit_average = np.average(right_fit, axis=0)
        right_line = make_coordinates(image, right_fit_average)
        averaged_lines.append(right_line)
    return averaged_lines        

def region_of_interest(image):
    height = image.shape[0]
    polygons = np.array([
        #Our Triangle
        [(200, height), (1100, height), (550,250)]
        ])
    #create a mask(black[zeros...])
    mask = np.zeros_like(image)
    #Then we fill the polygon(our triangle) with white...
    cv2.fillPoly(mask, polygons, 255)
    #runnign bitwise to ignore everything which is out of our mask
    masked_image = cv2.bitwise_and(image,mask)
    return masked_image

#Uncomment to show the image based logic
# =============================================================================
# image = cv2.imread('test_image.jpg')
# lane_image = np.copy(image)
# canny_image = canny(lane_image)
# cropped_image = region_of_interest(canny_image)
# #Hough Tranform to detect lines
# lines = cv2.HoughLinesP(cropped_image, 2, np.pi/180, 100, np.array([]), minLineLength=40, maxLineGap=5)
# #Taking one left and right line by averaging the found lines into a single 1
# averaged_lines = average_slope_intercept(lane_image, lines)
# #Then we create an image with the lines
# line_image = display_lines(lane_image, averaged_lines)
# #And wwe add some overlay on top of the original image
# combo_image = cv2.addWeighted(lane_image, 0.8, line_image, 1, 1)
# cv2.imshow('canny',combo_image)
# cv2.waitKey(0) # Wait forever!
# =============================================================================

cap = cv2.VideoCapture('test_video.mp4')
while(cap.isOpened()):
    read_ok,frame_image = cap.read()
    if read_ok:
        canny_image = canny(frame_image)
        cropped_image = region_of_interest(canny_image)
        #Hough Tranform to detect lines
        lines = cv2.HoughLinesP(cropped_image, 2, np.pi/180, 100, np.array([]), minLineLength=40, maxLineGap=5)
        #Taking one left and right line by averaging the found lines into a single 1
        averaged_lines = average_slope_intercept(frame_image, lines)
        #Then we create an image with the lines
        line_image = display_lines(frame_image, averaged_lines)
        #And wwe add some overlay on top of the original image
        combo_image = cv2.addWeighted(frame_image, 0.8, line_image, 1, 1)
        cv2.imshow('canny',combo_image)    
         # wait 1 millisecond or until q is pressed
        if cv2.waitKey(1) == ord('q'):
            break
    else: #get out as the video is pürobably over!!!
        break
cap.release()
cv2.destroyAllWindows()



